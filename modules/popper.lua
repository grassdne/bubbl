local Text = require "text"
local Effect = require "effects"
local BUBBLE_COUNT = 10

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

local VAR = {
    BUBBLE_SATURATION = 0.9,
    BUBBLE_LIGHTNESS = 0.5,
}

local Class = function (init)
    local class = {}
    setmetatable(class, {
        __call = function (self, ...)
            local t = setmetatable({}, self)
            init(t, ...)
            return t
        end,
    })
    -- Class is the metatable of its instance
    -- and its __index table
    class.__index = class
    return class
end

local pop_effects, bubbles
local score = 0
local scene
local Game, Won
local tutorial_text = Effect:Build("CLICK or press SPACE over bubbles to POP them", {
    speed = resolution.x,
    position = "left",
    color = Color.Hsl(0, 1, 0.5)
})

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
        return p
    end,
    Color = function (bubble)
        return Color.Hsl(bubble.hue*360, VAR.BUBBLE_SATURATION, VAR.BUBBLE_LIGHTNESS)
    end,
    Velocity = function (bubble)
        return bubble.velocity
    end,
    Radius = function (bubble)
        return bubble.radius
    end,
    Render = function (bubble)
        RenderBubble(bubble.position, bubble:Color(), bubble:Radius())
    end,
}

local RandomPositionInRadius = function (max_distance)
    local theta = math.random() * 2 * math.pi
    local r = math.random() * max_distance
    return Vector2.Angle(theta) * r
end

local ParticleUpdatePosition = function (point, dt)
    local next_position = point.position + point.delta * dt
    local diff = point.goal - point.position
    if diff.x * point.delta.x > 0 or diff.y * point.delta.y > 0 then
        point.position = next_position
    else
        point.position = point.goal
    end
end

local SpawnBubble = function (self, pos)
    score = score + 1
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

local PopEffectFromBubble = function (self, bubble)
    table.insert(pop_effects, CreatePopEffect(bubble.position, bubble:Color(), bubble:Radius(), bubble:Velocity()))
end

local PopBubble = function(self, i)
    score = score - 1
    local bubble = table.remove(bubbles, i)
    if score <= 0 then
        scene = Won(bubble)
    else
        PopEffectFromBubble(self, bubble)
    end
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

local BubbleAtPoint = function (self, pos)
    for i, b in ipairs(bubbles) do
        if pos:Dist(b.position) < b:Radius() then
            return i, b
        end
    end
end

Game = Class(function (self)
    bubbles = {}
    pop_effects = {}
    for i=1, BUBBLE_COUNT do
        SpawnBubble(self)
    end
end)

function Game:Click (pos)
    local i = BubbleAtPoint(self, pos)
    tutorial_text:Disperse()
    if i then
        PopBubble(self, i)
    else
        SpawnBubble(self, pos)
    end
end
function Game:Draw(dt)
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

    Text.PutstringWithWidth(Vector2(0,0), tostring(score), 100, WEBCOLORS.BLACK)
    tutorial_text:Update(dt)
end

local WIN_EFFECT_PERIOD = 1
Won = Class(function (self, bubble)
    self.color = bubble:Color()
    local str = "Play again?"
    -- TODO: iterator rather than table returned by build_string_with_width
    self.particles = Text.BuildParticlesWithWidth(str, resolution.x)
    local center = Vector2(0, resolution.y - self.particles.height) / 2
    for i, particle in ipairs(self.particles) do
        particle.position = bubble.position + RandomPositionInRadius(bubble:Radius())
        particle.goal = center + particle.offset
        local difference = particle.goal - particle.position
        particle.delta = difference / WIN_EFFECT_PERIOD
    end
end)

function Won:Draw(dt)
    RunBgShader("elastic", BgShaderLoader, {
        resolution = resolution,
        num_elements = 1,
        colors = self.color,
        positions = { resolution / 2 },
    })
    for i, particle in ipairs(self.particles) do
        ParticleUpdatePosition(particle, dt)
        RenderPop(particle.position, self.color, particle.radius)
    end
end

function Won:Click()
    scene = Game()
end

return {
    title = "Popper",

    -- TODO: why doesn't OnMouseDown pass a Vector2
    OnMouseDown = function(x, y) scene:Click(Vector2(x, y)) end,

    OnKey = function(key, down)
        if key == "Space" and down then
            scene:Click(MousePosition())
        end
    end,

    Draw = function (dt)
        scene:Draw(dt)
    end,

    OnStart = function()
        scene = Game()
    end,
}
