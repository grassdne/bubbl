local text = require "text"
local Effect = require "effects"
local INITIAL_BUBBLE_COUNT = 20

local BGSHADER_MAX_ELEMS = 10
local BUBBLE_RAD_BASE = 30
local BUBBLE_RAD_VARY = 25
local MAX_GROWTH = 200
local MIN_GROWTH_RATE = 50
local MAX_GROWTH_RATE = 225
local TRANS_IMMUNE_PERIOD = 1
local TRANS_TIME = 1
local POP_EXPAND_MULT = 2.0
local POP_LAYER_WIDTH = 10.0
local POP_PARTICLE_LAYOUT = 5
local POP_LIFETIME = 1.0
local POP_PT_RADIUS = 7.0
local POP_PT_RADIUS_DELTA = 4.0
local TRANSFORM_TIME = 1.0
local POP_PARTICLE_SPEED = 300

local BUBBLE_SPEED_VARY = 200
local BUBBLE_SPEED_BASE = 200

local BUBBL_SPAWN_ANIM_TIME = 0.1

local VAR = {
    BUBBLE_SATURATION = 0.9,
    BUBBLE_LIGHTNESS = 0.5,
}

local TEXT_COLOR = Color.Hsl(260, 1, 0.4, 0.8)

local score = INITIAL_BUBBLE_COUNT
local pop_effects = {}
local bubbles = {}
-- We use this in the win condition
local last_popped_bubble

---@type "playing" | "won"
local game_state = "playing"

local SCORE_WIDTH = 150
local SCORE_ANIM_TIME = 0.5
local GenText = function (opts)
    local particles = text.BuildParticlesWithWidth(opts.str, opts.width)
    particles.base_position = Vector2(resolution.x - opts.width, resolution.y - particles.height) / 2
    return random.shuffle(particles)
end
local the_text = {
    Build = function (self, build_opts)
        self.particles = {}
        self.next = nil
        -- Keeping a single element queue keeps us from needing
        -- to interrupt the current transition
        self.queue = nil
        self:QueueTransform(build_opts)
    end;

    Update = function (self, dt)
        if self.queue and not self.next then
            -- Move up queue'd transition
            self.next = self.queue
            self.queue = nil
            self.next.transition_start = Seconds()
        end

        if not self.next then
            -- No active animation
            for i=1, #self.particles do
                RenderPop(self.particles.base_position + self.particles[i].offset, TEXT_COLOR, self.particles[i].radius)
            end
        else -- Perform transition animation
            -- There is no mutated state during an animation
            -- only an interpolation based on t
            local t = (Seconds() - self.next.transition_start) / SCORE_ANIM_TIME

            -- "Move" particles from self.particles to self.next
            for i=1, math.min(#self.particles, #self.next) do
                local position = Vector2.Lerp(self.particles.base_position + self.particles[i].offset, self.next.base_position + self.next[i].offset, t)
                local radius = Lerp(self.particles[i].radius, self.next[i].radius, t)
                RenderPop(position, TEXT_COLOR, radius)
            end

            -- Destroy excess particles
            -- when #self.particles > #self.next
            for i=#self.next+1, #self.particles do
                local radius = Lerp(self.particles[i].radius, 0, t)
                RenderPop(self.particles.base_position + self.particles[i].offset, TEXT_COLOR, radius)
            end

            -- Build new particles
            -- when #self.particles < #self.next
            for i=#self.particles+1, #self.next do
                local radius = Lerp(0, self.next[i].radius, t)
                RenderPop(self.next.base_position + self.next[i].offset, TEXT_COLOR, radius)
            end

            local transition_completed = t > 1
            if transition_completed then
                self.particles = self.next
                self.next = nil
            end
        end
    end;

    QueueTransform = function (self, build_opts)
        local new = GenText(build_opts)
        self.queue = new
    end;
}
the_text:Build { str="CLICK or press SPACE over bubbles to POP them", width=resolution.x }

local RandomVelocity = function()
    local Dimension = function()
        return random.sign() * random.vary(BUBBLE_SPEED_BASE, BUBBLE_SPEED_VARY)
    end
    return Vector2(Dimension(), Dimension())
end

local RandomRadius = function()
    return random.vary(BUBBLE_RAD_BASE, BUBBLE_RAD_VARY)
end

local RandomPosition = function()
    return Vector2(math.random(), math.random()):Scale(resolution)
end

local BgShaderLoader = function()
    local contents = ReadEntireFile("shaders/elasticbubbles_bg.frag")
    return string.format("#version 330\n#define MAX_ELEMENTS %d\n%s", BGSHADER_MAX_ELEMS, contents)
end

local Particle = Parent {
    New = function (Self, pos, velocity)
        local p = setmetatable({}, Self)
        p.velocity = velocity
        p.pos = pos
        return p
    end;
}

local Bubble = Parent {
    New = function (Self, position, velocity, radius)
        local p = setmetatable({}, Self)
        p.position = position
        p.radius = radius
        p.hue = math.random()
        p.velocity = velocity
        p.birth = Seconds()
        return p
    end,
    Color = function (bubble)
        return Color.Hsl(bubble.hue*360, VAR.BUBBLE_SATURATION, VAR.BUBBLE_LIGHTNESS, 1)
    end,
    Velocity = function (bubble)
        return bubble.velocity
    end,
    Radius = function (bubble)
        local time = Seconds()
        local t = math.min(1, (time - bubble.birth) / BUBBL_SPAWN_ANIM_TIME)
        return Lerp(0, bubble.radius, t)
    end,
    Render = function (bubble)
        RenderBubble(bubble.position, bubble:Color(), bubble:Radius())
    end,
}

local SpawnBubble = function (pos)
    table.insert(bubbles, Bubble:New(pos or RandomPosition(), RandomVelocity(), RandomRadius()))
end

local ParticleVelocity = function (bubble_velocity)
    return Vector2.Angle(math.random()*2*math.pi) * POP_PARTICLE_SPEED + bubble_velocity
end

local CreatePopEffect = function (center, color, size, bubble_velocity)
    local pop = {
        pt_radius = POP_PT_RADIUS,
        color = color,

        -- Center bubble
        [1] = Particle:New(center, ParticleVelocity(bubble_velocity))
    }

    local distance = 0
    local num_particles_in_layer = 0
    while distance < size - POP_PT_RADIUS do
        distance = distance + POP_LAYER_WIDTH
        num_particles_in_layer = num_particles_in_layer + POP_PARTICLE_LAYOUT
        for i = 1, num_particles_in_layer do
            local theta = 2*PI / num_particles_in_layer * i
            local dir = Vector2(math.cos(theta), math.sin(theta))

            -- Before velocity was in direction dir
            --local velocity = dir * (POP_EXPAND_MULT * distance / POP_LIFETIME)
            -- instead make it random
            local velocity = ParticleVelocity(bubble_velocity)
            table.insert(pop, Particle:New(dir * distance + center, velocity))
        end
    end
    pop.start_time = Seconds()
    return pop
end

local PopEffectFromBubble = function (bubble)
    table.insert(pop_effects, CreatePopEffect(bubble.position, bubble:Color(), bubble:Radius(), bubble:Velocity()))
end

local Won = function ()
    game_state = "won"
    the_text:QueueTransform({ str="Play again?", width=resolution.x })
end

local PopBubble = function(i)
    last_popped_bubble = table.remove(bubbles, i)
    PopEffectFromBubble(last_popped_bubble)
    if #bubbles <= 0 then Won() end
end

local IsCollision = function (a, b)
    local mindist = a:Radius() + b:Radius()
    return a ~= b and Vector2.DistSq(a.position, b.position) < mindist*mindist
end

local SwapVelocities = function (a, b)
    a.velocity, b.velocity = b.velocity, a.velocity
end

local SeparateBubbles = function (a, b)
    -- Push back bubble a so it is no longer colliding with b
    local dir_b_to_a = Vector2.Normalize(a.position - b.position)
    local mindist = a:Radius() + b:Radius()
    a.position = b.position + dir_b_to_a * mindist
end

local EnsureBubbleInBounds = function (bubble)
    bubble.position.x = math.clamp(bubble.position.x, bubble:Radius(), resolution.x  - bubble:Radius())
    bubble.position.y = math.clamp(bubble.position.y, bubble:Radius(), resolution.y - bubble:Radius())
end

local MoveBubble = function (bubble, dt)
    local next = bubble.position + bubble:Velocity() * dt
    local max_y = resolution.y - bubble:Radius()
    local max_x = resolution.x - bubble:Radius()
    if next.x < bubble:Radius() or next.x > max_x then
        bubble.velocity.x = -bubble.velocity.x
    else
        bubble.position.x = next.x
    end
    if next.y < bubble:Radius() or next.y > max_y then
        bubble.velocity.y = -bubble.velocity.y
    else
        bubble.position.y = next.y
    end
end

local BubbleAtPoint = function (pos)
    for i, b in ipairs(bubbles) do
        if pos:Dist(b.position) < b:Radius() then
            return i, b
        end
    end
end

local function Start()
    bubbles = {}
    for i=1, INITIAL_BUBBLE_COUNT do
        SpawnBubble()
    end
end

local function Click (pos)
    if game_state == "playing" then
        local i = BubbleAtPoint(pos)
        if i then
            PopBubble(i)
        else
            SpawnBubble(pos)
        end
    elseif game_state == "won" then
        -- Restart!
        game_state = "playing"
        Start()
    end
end

return {
    title = "Popper",

    -- TODO: why doesn't OnMouseDown pass a Vector2
    OnMouseDown = function(x, y) Click(Vector2(x, y)) end,

    OnKey = function(key, down)
        if key == "Space" and down then
            Click(MousePosition())
        end
    end,

    Draw = function (dt)
        local time = Seconds()
        --- Move bubbles ---
        for _, bubble in ipairs(bubbles) do
            MoveBubble(bubble, dt)
            EnsureBubbleInBounds(bubble)
        end

        --- Handle collisions ---
        for _, a in ipairs(bubbles) do
            for _, b in ipairs(bubbles) do
                if IsCollision(a, b) then
                    SwapVelocities(a, b)
                    SeparateBubbles(a, b)
                end
            end
        end

        --- Render bubbles ---
        for i, bubble in ipairs(bubbles) do bubble:Render() end

        -- Pop effects are hopefully in chronological order
        for i = #pop_effects, 1, -1 do
            if time - pop_effects[i].start_time < POP_LIFETIME then
                break
            end
            pop_effects[i] = nil
        end
        --- Update pop effect particles ---
        for _, pop in ipairs(pop_effects) do
            pop.pt_radius = pop.pt_radius + POP_PT_RADIUS_DELTA * dt
            local age = time - pop.start_time
            pop.color.a = 1 - age / POP_LIFETIME
            for _, pt in ipairs(pop) do
                pt.pos = pt.pos + pt.velocity * dt
                RenderPop(pt.pos, pop.color, pop.pt_radius)
            end
        end

        if game_state == "playing" then
            --- Draw background ---
            if #bubbles > 0 then
                table.sort(bubbles, function(a, b) return a:Radius() > b:Radius() end)
                local colors, positions = {}, {}
                for i=1, math.min(BGSHADER_MAX_ELEMS, #bubbles) do
                    local bub = bubbles[i]
                    colors[i] = bub:Color()
                    positions[i] = bub.position
                end
                RunBgShader("elastic", BgShaderLoader, {
                    resolution = resolution,
                    num_elements = #bubbles,
                    colors = colors,
                    positions = positions,
                })
            end

            if score ~= #bubbles then
                -- Score was updated
                score = #bubbles
                the_text:QueueTransform({ str=tostring(score), width=SCORE_WIDTH })
            end
        elseif game_state == "won" then
            RunBgShader("elastic", BgShaderLoader, {
                resolution = resolution,
                num_elements = 1,
                colors = { last_popped_bubble:Color() },
                positions = { resolution / 2 },
            })
        end

        the_text:Update()
    end,

    OnStart = function()
        Start()
    end,
}
