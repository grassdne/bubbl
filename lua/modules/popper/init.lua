local VAR = require "modules.popper.tweak"
local the_text = require "modules.popper.text"
local Bubble = require "modules.popper.bubble"
local background = require "modules.popper.background"

local BUBBLE_RAD_BASE = 30
local BUBBLE_RAD_VARY = 30
local BUBBLE_SPEED_VARY = 200
local BUBBLE_SPEED_BASE = 200

local POP_LAYER_WIDTH = 10.0
local POP_PARTICLE_LAYOUT = 5
local POP_LIFETIME = 1.0
local POP_PT_RADIUS = 7.0
local POP_PT_RADIUS_DELTA = 4.0
local POP_PARTICLE_SPEED = 300

local SCORE_WIDTH = 0.2

local score = VAR.INITIAL_BUBBLE_COUNT
local pop_effects = {}
local bubbles = {}

-- We use this in the win condition
local last_popped_bubble

---@type "playing" | "won"
local game_state = "playing"

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
        [1] = { pos=center, velocity=ParticleVelocity(bubble_velocity) }
    }

    local distance = 0
    local num_particles_in_layer = 0
    while distance < size - POP_PT_RADIUS do
        distance = distance + POP_LAYER_WIDTH
        num_particles_in_layer = num_particles_in_layer + POP_PARTICLE_LAYOUT
        for i = 1, num_particles_in_layer do
            local theta = 2*PI / num_particles_in_layer * i
            local dir = Vector2(math.cos(theta), math.sin(theta))

            table.insert(pop, {
                pos = dir * distance + center,
                velocity = ParticleVelocity(bubble_velocity),
            })
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
    the_text:QueueTransform({ str="Continue?", width=1 })
    VAR.INITIAL_BUBBLE_COUNT = VAR.INITIAL_BUBBLE_COUNT + 1
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
    game_state = "playing"
    bubbles = {}
    for i=1, VAR.INITIAL_BUBBLE_COUNT do
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
        Start()
    end
end

return {
    title = "Popper",

    tweak = {
        vars = VAR,
        { id="INITIAL_BUBBLE_COUNT", name="Count", type="range", min=1, max=100, step=1, callback=Start },
    },

    -- TODO: why doesn't OnMouseDown pass a Vector2
    OnMouseDown = function(x, y) Click(Vector2(x, y)) end,

    OnKey = function(key, down)
        if key == "Space" and down then
            Click(MousePosition())
        end
    end,

    Draw = function (dt)
        the_text:Update()

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
            background.Draw(bubbles)

            if score ~= #bubbles then
                -- Score was updated
                score = #bubbles
                the_text:QueueTransform({ str=tostring(score), width=SCORE_WIDTH })
            end
        elseif game_state == "won" then
            background.Draw({ last_popped_bubble })
        end
    end,

    OnStart = function()
        the_text:Build { str="CLICK or press SPACE over bubbles to POP them", width=1 }
        Start()
    end,
}
