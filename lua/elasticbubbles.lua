Title "Elastic Bubbles (Press to create or pop a bubble!)"

-- Globals initialized here!
bubbles = {}
pop_effects = {}
movement_enabled = true
shaders = {}
cursor_bubble = false
shaders.bg = BgShader:New()

local RandomVelocity = function()
    local Dimension = function()
        return random.sign() * random.vary(ELASTIC.BUBBLE_SPEED_BASE, ELASTIC.BUBBLE_SPEED_VARY)
    end
    return Vector2(Dimension(), Dimension())
end

local RandomRadius = function()
    return random.vary(ELASTIC.BUBBLE_RAD_BASE, ELASTIC.BUBBLE_RAD_VARY)
end

local RandomPosition = function()
    return Vector2(math.random()*window_width, math.random()*window_height)
end

local RandomColor = function()
    return Color.hsl(math.random()*360, ELASTIC.BUBBLE_HUE, ELASTIC.BUBBLE_LIGHTNESS)
end

local Particle = {
    New = function (Self, velocity, pos)
        local p = setmetatable({}, Self)
        p.velocity = velocity
        p.pos = pos
        return p
    end;
}

local CreatePopEffect = function (center, color, size)
    local pop = {
        pt_radius = ELASTIC.POP_PT_RADIUS,
        color = color,

        -- Center bubble
        [1] = Particle:New(Vector2(0,0), center)
    }

    local distance = 0
    local num_particles_in_layer = 0
    while distance < size - ELASTIC.POP_PT_RADIUS do
        distance = distance + ELASTIC.POP_LAYER_WIDTH
        num_particles_in_layer = num_particles_in_layer + ELASTIC.POP_PARTICLE_LAYOUT
        for i = 1, num_particles_in_layer do
            local theta = 2*PI / num_particles_in_layer * i
            local dir = Vector2(math.cos(theta), math.sin(theta))
            local velocity = dir * (ELASTIC.POP_EXPAND_MULT * distance / ELASTIC.POP_LIFETIME)
            table.insert(pop, Particle:New(velocity, dir * distance + center))
        end
    end
    pop.start_time = Seconds()
    return pop
end

local PopEffectFromBubble = function (bubble)
    table.insert(pop_effects, CreatePopEffect(bubble.position, bubble.color, bubble.radius))
end

local PopBubble = function(i)
    local bubble = table.remove(bubbles, i)
    PopEffectFromBubble(bubble)
end

local IsCollision = function (a, b)
    local mindist = a.radius + b.radius
    return a ~= b and Vector2.distsq(a.position, b.position) < mindist*mindist
end

local SwapVelocities = function (a, b)
    a.velocity, b.velocity = b.velocity, a.velocity
end

local SeparateBubbles = function (a, b)
    -- Push back bubble a so it is no longer colliding with b
    local dir_b_to_a = Vector2.normalize(a.position - b.position)
    local mindist = a.radius + b.radius
    a.position = b.position + dir_b_to_a * mindist
end

local EnsureBubbleInBounds = function (bubble)
    local pos = bubble.position
    pos.x = math.clamp(pos.x, bubble.radius, window_width  - bubble.radius)
    pos.y = math.clamp(pos.y, bubble.radius, window_height - bubble.radius)
    bubble.position = pos
end

local CollectAllBubbles = function ()
    local all_bubbles = {}
    if cursor_bubble then table.insert(all_bubbles, cursor_bubble) end
    for _, b in pairs(bubbles) do table.insert(all_bubbles, b) end
    return all_bubbles
end

local GetBubblesForBgshader = function ()
    local all_bubbles = CollectAllBubbles()
    table.sort(all_bubbles, function(a, b) return a.radius > b.radius end)
    local ents = {}
    for i=1, math.min(#all_bubbles, BGSHADER_MAX_ELEMS) do 
        ents[i] = all_bubbles[i]:CBubble()
    end
    return ents
end

local StartTransition = function (bubble, other)
    bubble:StartTransformation(other.color, Seconds(),
        (other.position - bubble.position):normalize())
end
local StopTransition = function (bubble)
    bubble.trans_starttime = nil
    bubble.color = bubble.color_b
    bubble.last_transition = Seconds();
end

local MoveBubble = function (bubble, dt)
    local next = bubble.position + bubble.velocity:scale(dt)
    local max_y = window_height - bubble.radius
    local max_x = window_width - bubble.radius
    if next.x < bubble.radius or next.x > max_x then
        bubble.velocity.x = -bubble.velocity.x
        bubble.velocity.y = -bubble.velocity.y
    end
    if next.y < bubble.radius or next.y > max_y then
        bubble.velocity.y = -bubble.velocity.y
    end
    bubble.position = next
end

OnUpdate = function(dt)
    local time = Seconds()

    -- Grow bubble under mouse
    if cursor_bubble then
        local percent_complete = cursor_bubble.radius / ELASTIC.MAX_GROWTH
        local growth_rate = percent_complete * (ELASTIC.MAX_GROWTH_RATE - ELASTIC.MIN_GROWTH_RATE) + ELASTIC.MIN_GROWTH_RATE
        cursor_bubble.radius = cursor_bubble.radius + growth_rate * dt
        EnsureBubbleInBounds(cursor_bubble)
        if cursor_bubble.radius > ELASTIC.MAX_GROWTH then
            PopEffectFromBubble(cursor_bubble)
            cursor_bubble = false
        end
    end
    -- Move bubbles
    for _, bubble in pairs(bubbles) do
        assert(bubble ~= cursor_bubble)
        if movement_enabled and not bubble.trans_starttime then
            MoveBubble(bubble, dt)
        end
        if bubble.trans_starttime and time - bubble.trans_starttime > ELASTIC.TRANS_TIME then
            StopTransition(bubble)
        end
        EnsureBubbleInBounds(bubble)
    end
    -- Handle collisions
    for _, a in pairs(bubbles) do
        for _, b in pairs(bubbles) do
            if IsCollision(a, b) then
                SwapVelocities(a, b)
                SeparateBubbles(a, b)

                if not a.trans_starttime and not b.trans_starttime
                    and time - (a.last_transition or 0) > ELASTIC.TRANS_IMMUNE_PERIOD
                    and time - (b.last_transition or 0) > ELASTIC.TRANS_IMMUNE_PERIOD
                then
                    StartTransition(a, b);
                    StartTransition(b, a);
                end
            end
        end
        if cursor_bubble and IsCollision(a, cursor_bubble) then
            -- TODO: Should bubbles that collide with cursor bubble bounce backwards?
            SeparateBubbles(a, cursor_bubble)
        end
    end

    -- Render bubbles
    for _, bubble in ipairs(bubbles) do
        if bubble.trans_starttime then
            bubble.trans_percent = (time - bubble.trans_starttime) / ELASTIC.TRANSFORM_TIME
        end
        RenderBubble(bubble)
    end
    if cursor_bubble then RenderBubble(cursor_bubble) end

    -- Update pop effect particles
    for _, pop in ipairs(pop_effects) do
        pop.pt_radius = pop.pt_radius + ELASTIC.POP_PT_RADIUS_DELTA * dt
        pop.age = time - pop.start_time
        for _, pt in ipairs(pop) do
            pt.pos = pt.pos + pt.velocity * dt
            RenderPop(pt.pos, pop.color, pop.pt_radius, pop.age)
        end
    end
    -- Pop effects should be in chronological order
    for i = #pop_effects, 1, -1 do
        if time - pop_effects[i].start_time < ELASTIC.POP_LIFETIME then
            break
        end
        pop_effects[i] = nil
    end

    -- Draw bubbles!
    shaders.bg:draw(GetBubblesForBgshader())
end

local BubbleAtPoint = function (pos)
    for i, b in pairs(bubbles) do
        if pos:dist(b.position) < b.radius then
            return i, b
        end
    end
end

OnMouseDown = function(x, y)
    if cursor_bubble then return end
    local i = BubbleAtPoint(Vector2(x, y))
    if i then
        PopBubble(i)
    else
        cursor_bubble = Bubble:New(RandomColor(), Vector2(x, y), RandomVelocity(), RandomRadius())
    end
end

OnMouseUp = function(x, y)
    if cursor_bubble then
        table.insert(bubbles, cursor_bubble)
        cursor_bubble = false
    end
end

OnMouseMove = function(x, y)
    if cursor_bubble then
        cursor_bubble.position = Vector2(x, y)
    end
end

OnKey = function(key, down)
    if down and key == "Space" then
        movement_enabled = not movement_enabled
    elseif down and key == "Backspace" then
        for i = #bubbles, 1, -1 do
            PopBubble(i)
        end
    end
end

for i=1, ELASTIC.STARTING_BUBBLE_COUNT do
    table.insert(bubbles, Bubble:New(RandomColor(), RandomPosition(), RandomVelocity(), RandomRadius()))
end

-- Any more globals is an error!
LockGlobalTable()
