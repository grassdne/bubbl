local bubbles = {}
local pop_effects = {}
local cursor_bubble
local movement_enabled = true

local BGSHADER_MAX_ELEMS = 10
local STARTING_BUBBLE_COUNT = 10
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

local BUBBLE_SPEED_VARY = 100
local BUBBLE_SPEED_BASE = 100

local VAR = {
    BUBBLE_SATURATION = 0.9,
    BUBBLE_LIGHTNESS = 0.5,
    BUBBLE_SPEED_FACTOR = 2,
    BUBBLE_SIZE_FACTOR = 1,
}

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
        return bubble.velocity * VAR.BUBBLE_SPEED_FACTOR
    end,
    Radius = function (bubble)
        return bubble.radius * VAR.BUBBLE_SIZE_FACTOR
    end,
    Render = function (bubble)
        RenderBubble(bubble.position, bubble:Color(), bubble:Radius())
    end,
}

local SpawnBubble = function ()
    table.insert(bubbles, Bubble:New(RandomPosition(), RandomVelocity(), RandomRadius()))
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

local PopBubble = function(i)
    local bubble = table.remove(bubbles, i)
    PopEffectFromBubble(bubble)
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

local CollectAllBubbles = function ()
    local all_bubbles = {}
    if cursor_bubble then table.insert(all_bubbles, cursor_bubble) end
    for _, b in ipairs(bubbles) do table.insert(all_bubbles, b) end
    return all_bubbles
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

local Press = function ()
    if cursor_bubble then return end
    local i = BubbleAtPoint(MousePosition())
    if i then
        PopBubble(i)
    else
        cursor_bubble = Bubble:New(MousePosition(), RandomVelocity(), BUBBLE_RAD_BASE)
    end
end

local Release = function ()
    if not cursor_bubble then return end
    table.insert(bubbles, cursor_bubble)
    cursor_bubble = false
end

return {
    title = "Elastic Bubbles (Press to create or pop a bubble!)",
    tweak = {
        vars = VAR,
        { id="BUBBLE_SATURATION", name="Saturation", type="range", min=0, max=1 },
        { id="BUBBLE_LIGHTNESS", name="Lightness", type="range", min=0, max=1 },
        { id="BUBBLE_SPEED_FACTOR", name="Bubble Speed", type="range", min=0, max=10 },
        { id="BUBBLE_SIZE_FACTOR", name="Bubble Size", type="range", min=0, max=2 },
        { id="COUNT", name="Bubble Count", value=function () return #bubbles end,
          type="range", min=0, max=100, step=1, callback=function (count)
            for i=#bubbles+1, count do SpawnBubble() end
            for i=#bubbles, count+1, -1 do PopBubble(i) end
        end },
    },

    OnMouseDown = function(x, y) Press() end,

    OnMouseUp = function(x, y) Release() end,

    OnMouseMove = function(x, y)
        if cursor_bubble then cursor_bubble.position = Vector2(x, y) end
    end,

    OnKey = function(key, down)
        if down and key == "Space" then
            movement_enabled = not movement_enabled
        elseif down and key == "Backspace" then
            for i = #bubbles, 1, -1 do
                PopBubble(i)
            end
        elseif key == "Return" then
            if down then Press() else Release() end
        end
    end,

    OnStart = function()
        if #bubbles == 0 then
            -- Create starting bubbles
            for i=1, STARTING_BUBBLE_COUNT do
                SpawnBubble()
            end
        end
    end,

    Draw = function(dt)
        local time = Seconds()
        --- Grow bubble under mouse ---
        if cursor_bubble then
            local percent_complete = cursor_bubble.radius / MAX_GROWTH
            local growth_rate = percent_complete * (MAX_GROWTH_RATE - MIN_GROWTH_RATE) + MIN_GROWTH_RATE
            cursor_bubble.radius = cursor_bubble.radius + growth_rate * dt
            EnsureBubbleInBounds(cursor_bubble)
            if cursor_bubble.radius > MAX_GROWTH then
                PopEffectFromBubble(cursor_bubble)
                cursor_bubble = false
            end
        end

        --- Move bubbles ---
        for _, bubble in ipairs(bubbles) do
            assert(bubble ~= cursor_bubble)
            if movement_enabled and not bubble.trans_starttime then
                MoveBubble(bubble, dt)
            end
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
            if cursor_bubble and IsCollision(a, cursor_bubble) then
                -- TODO: Should bubbles that collide with cursor bubble bounce backwards?
                SeparateBubbles(a, cursor_bubble)
            end
        end

        local all_bubbles = CollectAllBubbles()

        --- Render bubbles ---
        for i, bubble in ipairs(all_bubbles) do bubble:Render() end

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
        -- Pop effects are hopefully in chronological order
        for i = #pop_effects, 1, -1 do
            if time - pop_effects[i].start_time < POP_LIFETIME then
                break
            end
            pop_effects[i] = nil
        end

        --- Draw background ---
        if #all_bubbles > 0 then
            table.sort(all_bubbles, function(a, b) return a:Radius() > b:Radius() end)
            local colors, positions = {}, {}
            for i=1, math.min(BGSHADER_MAX_ELEMS, #all_bubbles) do
                local bub = all_bubbles[i]
                colors[i] = bub:Color()
                positions[i] = bub.position
            end
            RunBgShader("elastic", BgShaderLoader, {
                resolution = resolution,
                num_elements = #all_bubbles,
                colors = colors,
                positions = positions,
            })
        end
    end,
}
