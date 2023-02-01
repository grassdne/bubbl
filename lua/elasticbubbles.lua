title = "Elastic Bubbles (Press to create or pop a bubble!)"

-- Globals initialized here!
bubbles = {}
pop_effects = {}
movement_enabled = true
shaders = {}
cursor_bubble = false
shaders.bg = BgShader:new()

local ffi = require "ffi"

local random_velocity = function()
    local dimension = function()
        return random.sign() * random.vary(ELASTIC.BUBBLE_SPEED_BASE, ELASTIC.BUBBLE_SPEED_VARY)
    end
    return Vector2(dimension(), dimension())
end

local random_radius = function()
    return random.vary(ELASTIC.BUBBLE_RAD_BASE, ELASTIC.BUBBLE_RAD_VARY)
end

local random_position = function()
    return Vector2(math.random()*window_width, math.random()*window_height)
end

local random_color = function()
    return Color.hsl(math.random()*360, ELASTIC.BUBBLE_HUE, ELASTIC.BUBBLE_LIGHTNESS)
end

local Particle = {
    new = function (Self, velocity, pos)
        local p = setmetatable({}, Self)
        p.velocity = velocity
        p.pos = pos
        return p
    end;
}

local create_pop_effect = function (center, color, size)
    local pop = {
        pt_radius = ELASTIC.POP_PT_RADIUS,
        color = color,

        -- Center bubble
        [1] = Particle:new(Vector2(0,0), center)
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
            table.insert(pop, Particle:new(velocity, dir * distance + center))
        end
    end
    pop.start_time = ffi.C.get_time()
    return pop
end

local pop_effect_from_bubble = function (bubble)
    table.insert(pop_effects, create_pop_effect(bubble.position, bubble.color, bubble.radius))
end

local pop_bubble = function(i)
    local bubble = table.remove(bubbles, i)
    pop_effect_from_bubble(bubble)
end

local is_collision = function (a, b)
    local mindist = a.radius + b.radius
    return a ~= b and Vector2.distsq(a.position, b.position) < mindist*mindist
end

local swap_velocities = function (a, b)
    local av, bv = a.velocity, b.velocity
    a.velocity = bv
    b.velocity = av
end

local separate_bubbles = function (a, b)
    -- Push back bubble a so it is no longer colliding with b
    local dir_b_to_a = Vector2.normalize(a.position - b.position)
    local mindist = a.radius + b.radius
    a.position = b.position + dir_b_to_a * mindist
end

local ensure_bubble_in_bounds = function (bubble)
    local pos = bubble.position
    pos.x = math.clamp(pos.x, bubble.radius, window_width  - bubble.radius)
    pos.y = math.clamp(pos.y, bubble.radius, window_height - bubble.radius)
    bubble.position = pos
end

local collect_all_bubbles = function ()
    local all_bubbles = {}
    if cursor_bubble then table.insert(all_bubbles, cursor_bubble) end
    for _, b in pairs(bubbles) do table.insert(all_bubbles, b) end
    return all_bubbles
end

local get_bubbles_for_bgshader = function ()
    local all_bubbles = collect_all_bubbles()
    table.sort(all_bubbles, function(a, b) return a.radius > b.radius end)
    local ents = {}
    for i=1, math.min(#all_bubbles, BGSHADER_MAX_ELEMS) do 
        ents[i] = all_bubbles[i]:c_bubble()
    end
    return ents
end

local start_transition = function (bubble, other)
    bubble:start_transformation(other.color, ffi.C.get_time(),
        (other.position - bubble.position):normalize())
end
local stop_transition = function (bubble)
    bubble.trans_starttime = nil
    bubble.color = bubble.color_b
    bubble.last_transition = ffi.C.get_time();
end

local move_bubble = function (bubble, dt)
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

on_update = function(dt)
    local time = ffi.C.get_time()

    -- Grow bubble under mouse
    if cursor_bubble then
        local percent_complete = cursor_bubble.radius / ELASTIC.MAX_GROWTH
        local growth_rate = percent_complete * (ELASTIC.MAX_GROWTH_RATE - ELASTIC.MIN_GROWTH_RATE) + ELASTIC.MIN_GROWTH_RATE
        cursor_bubble.radius = cursor_bubble.radius + growth_rate * dt
        ensure_bubble_in_bounds(cursor_bubble)
        if cursor_bubble.radius > ELASTIC.MAX_GROWTH then
            pop_effect_from_bubble(cursor_bubble)
            cursor_bubble = false
        end
    end
    -- Move bubbles
    for _, bubble in pairs(bubbles) do
        assert(bubble ~= cursor_bubble)
        if movement_enabled and not bubble.trans_starttime then
            move_bubble(bubble, dt)
        end
        if bubble.trans_starttime and time - bubble.trans_starttime > ELASTIC.TRANS_TIME then
            stop_transition(bubble)
        end
        ensure_bubble_in_bounds(bubble)
    end
    -- Handle collisions
    for _, a in pairs(bubbles) do
        for _, b in pairs(bubbles) do
            if is_collision(a, b) then
                swap_velocities(a, b)
                separate_bubbles(a, b)

                if not a.trans_starttime and not b.trans_starttime
                    and time - (a.last_transition or 0) > ELASTIC.TRANS_IMMUNE_PERIOD
                    and time - (b.last_transition or 0) > ELASTIC.TRANS_IMMUNE_PERIOD
                then
                    start_transition(a, b);
                    start_transition(b, a);
                end
            end
        end
        if cursor_bubble and is_collision(a, cursor_bubble) then
            -- TODO: Should bubbles that collide with cursor bubble bounce backwards?
            separate_bubbles(a, cursor_bubble)
        end
    end

    -- Render bubbles
    for _, bubble in ipairs(bubbles) do
        if bubble.trans_starttime then
            bubble.trans_percent = (time - bubble.trans_starttime) / ELASTIC.TRANSFORM_TIME
        end
        render_bubble(bubble)
    end
    if cursor_bubble then render_bubble(cursor_bubble) end

    -- Update pop effect particles
    for _, pop in ipairs(pop_effects) do
        pop.pt_radius = pop.pt_radius + ELASTIC.POP_PT_RADIUS_DELTA * dt
        pop.age = time - pop.start_time
        for _, pt in ipairs(pop) do
            pt.pos = pt.pos + pt.velocity * dt
            render_pop(pt.pos, pop.color, pop.pt_radius, pop.age)
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
    shaders.bg:draw(get_bubbles_for_bgshader())
end

local bubble_at_point = function (pos)
    for i, b in pairs(bubbles) do
        if pos:dist(b.position) < b.radius then
            return i, b
        end
    end
end

on_mouse_down = function(x, y)
    if cursor_bubble then return end
    local i = bubble_at_point(Vector2(x, y))
    if i then
        pop_bubble(i)
    else
        cursor_bubble = Bubble:new(random_color(), Vector2(x, y), random_velocity(), random_radius())
    end
end

on_mouse_up = function(x, y)
    if cursor_bubble then
        table.insert(bubbles, cursor_bubble)
        cursor_bubble = false
    end
end

on_mouse_move = function(x, y)
    if cursor_bubble then
        cursor_bubble.position = Vector2(x, y)
    end
end

on_key = function(key, down)
    if down and key == "Space" then
        movement_enabled = not movement_enabled
    elseif down and key == "Backspace" then
        for i = #bubbles, 1, -1 do
            pop_bubble(i)
        end
    end
end

for i=1, ELASTIC.STARTING_BUBBLE_COUNT do
    table.insert(bubbles, Bubble:new(random_color(), random_position(), random_velocity(), random_radius()))
end

-- Any more globals is an error!
lock_global_table()
