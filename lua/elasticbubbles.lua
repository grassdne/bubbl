title = "Elastic Bubbles"

local ffi = require "ffi"
local add_bubble = function (bubble)
    bubbles[bubble.id] = bubble;
end

local random_velocity = function()
    return Vector2(random.sign() * random.vary(ELASTICBUBBLES.BUBBLE_SPEED_BASE, ELASTICBUBBLES.BUBBLE_SPEED_VARY),
    random.sign() * random.vary(ELASTICBUBBLES.BUBBLE_SPEED_BASE, ELASTICBUBBLES.BUBBLE_SPEED_VARY))
end

local random_radius = function()
    return random.vary(ELASTICBUBBLES.BUBBLE_RAD_BASE, ELASTICBUBBLES.BUBBLE_RAD_VARY)
end

local random_position = function()
    return Vector2(math.random()*window_width, math.random()*window_height)
end

local random_color = function()
    return Color.hsl(math.random()*360, ELASTICBUBBLES.BUBBLE_HUE, ELASTICBUBBLES.BUBBLE_LIGHTNESS)
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
        pt_radius = ELASTICBUBBLES.POP_PT_RADIUS,
        color = color,

        -- Center bubble
        [1] = Particle:new(Vector2(0,0), center)
    }

    local distance = 0
    local num_particles_in_layer = 0
    while distance < size - ELASTICBUBBLES.POP_PT_RADIUS do
        distance = distance + ELASTICBUBBLES.POP_LAYER_WIDTH
        num_particles_in_layer = num_particles_in_layer + ELASTICBUBBLES.POP_PARTICLE_LAYOUT
        for i = 1, num_particles_in_layer do
            local theta = 2*PI / num_particles_in_layer * i
            local dir = Vector2(math.cos(theta), math.sin(theta))
            local velocity = dir * (ELASTICBUBBLES.POP_EXPAND_MULT * distance / ELASTICBUBBLES.POP_LIFETIME)
            table.insert(pop, Particle:new(velocity, dir * distance + center))
        end
    end
    pop.start_time = ffi.C.get_time()
    return pop
end

local pop_bubble = function(bubble)
    table.insert(pop_effects, create_pop_effect(bubble:position(), bubble:color(), bubble:radius()))
    shaders.bubble:destroy_bubble(bubble.id)
    bubbles[bubble.id] = nil
end

local is_collision = function (a, b)
    local mindist = a:radius() + b:radius()
    return a ~= b and Vector2.distsq(a:position(), b:position()) < mindist*mindist
end

local swap_velocities = function (a, b)
    local av, bv = a:velocity(), b:velocity()
    a:velocity(bv)
    b:velocity(av)
end

local separate_bubbles = function (a, b)
    -- Push back bubble a so it is no longer colliding with b
    local dir_b_to_a = Vector2.normalize(a:position() - b:position())
    local mindist = a:radius() + b:radius()
    a:position(b:position() + dir_b_to_a * mindist)
end

minmax = function(x, min, max) return math.min(max, math.max(min, x)) end

local ensure_bubble_in_bounds = function (bubble)
    local pos = bubble:position()
    pos.x = minmax(pos.x, bubble:radius(), window_width  - bubble:radius())
    pos.y = minmax(pos.y, bubble:radius(), window_height - bubble:radius())
    bubble:position(pos)
end

local collect_all_bubbles = function ()
    local all_bubbles = {}
    if cursor_bubble then table.insert(all_bubbles, cursor_bubble) end
    for _, b in pairs(bubbles) do table.insert(all_bubbles, b) end
    return all_bubbles
end

local get_bubble_ids_for_bgshader = function ()
    local all_bubbles = collect_all_bubbles()
    table.sort(all_bubbles, function(a, b) return a:radius() > b:radius() end)
    local ids = {}
    for i=1, math.min(#all_bubbles, BGSHADER_MAX_ELEMS) do 
        ids[i] = all_bubbles[i].id
    end
    return ids
end

local start_transition = function (bubble, other)
    bubble:start_transformation(other:color(), ffi.C.get_time(),
        (other:position() - bubble:position()):normalize())
    bubble.in_transition = true
end
local stop_transition = function (bubble)
    bubble.in_transition = false
    bubble:color(bubble:transformation_color())
    bubble.last_transition = ffi.C.get_time();
end

local move_bubble = function (bubble, dt)
    local next = bubble:position() + bubble:velocity():scale(dt)
    local max_y = window_height - bubble:radius()
    local max_x = window_width - bubble:radius()
    if next.x < bubble:radius() or next.x > max_x then
        bubble:x_velocity(-bubble:x_velocity())
        bubble:y_velocity(-bubble:y_velocity())
    end
    if next.y < bubble:radius() or next.y > max_y then
        bubble:y_velocity(-bubble:y_velocity())
    end
    bubble:position(next)
end

on_update = function(dt)
    local time = ffi.C.get_time()

    -- Grow bubble under mouse
    if cursor_bubble then
        local percent_complete = cursor_bubble:radius() / ELASTICBUBBLES.MAX_GROWTH
        local growth_rate = percent_complete * (ELASTICBUBBLES.MAX_GROWTH_RATE - ELASTICBUBBLES.MIN_GROWTH_RATE) + ELASTICBUBBLES.MIN_GROWTH_RATE
        cursor_bubble:delta_radius(growth_rate * dt)
        ensure_bubble_in_bounds(cursor_bubble)
        if cursor_bubble:radius() > ELASTICBUBBLES.MAX_GROWTH then
            pop_bubble(cursor_bubble)
            cursor_bubble = false
        end
    end
    -- Move bubbles
    for _, bubble in pairs(bubbles) do
        assert(bubble ~= cursor_bubble)
        if movement_enabled and not bubble.in_transition then
            move_bubble(bubble, dt)
        end
        if bubble.in_transition and time - bubble.C.trans_starttime > ELASTICBUBBLES.TRANS_TIME then
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

                if not a.in_transition and not b.in_transition
                    and time - (a.last_transition or 0) > ELASTICBUBBLES.TRANS_IMMUNE_PERIOD
                    and time - (b.last_transition or 0) > ELASTICBUBBLES.TRANS_IMMUNE_PERIOD
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

    -- Update pop effect particles
    for _, pop in ipairs(pop_effects) do
        pop.pt_radius = pop.pt_radius + ELASTICBUBBLES.POP_PT_RADIUS_DELTA * dt
        pop.age = time - pop.start_time
        for _, pt in ipairs(pop) do
            pt.pos = pt.pos + pt.velocity * dt
            shaders.pop:render_particle(pt.pos, pop.color, pop.pt_radius, pop.age)
        end
    end
    -- Pop effects should be in chronological order
    for i = #pop_effects, 1, -1 do
        if time - pop_effects[i].start_time < ELASTICBUBBLES.POP_LIFETIME then
            break
        end
        pop_effects[i] = nil
    end

    -- Draw bubbles!
    shaders.bg:draw(get_bubble_ids_for_bgshader())
    shaders.pop:draw(dt)
    shaders.bubble:draw()
end

local bubble_at_point = function (pos)
    for id, b in pairs(bubbles) do
        if pos:dist(b:position()) < b:radius() then
            return b
        end
    end
end

on_mouse_down = function(x, y)
    if cursor_bubble then return end
    local bubble = bubble_at_point(Vector2(x, y))
    if bubble then
        pop_bubble(bubble)
    else
        cursor_bubble = shaders.bubble:create_bubble(random_color(), Vector2(x, y), random_velocity(), random_radius())
    end
end

on_mouse_up = function(x, y)
    if cursor_bubble then
        add_bubble(cursor_bubble)
        cursor_bubble = false
    end
end

on_mouse_move = function(x, y)
    if cursor_bubble then
        cursor_bubble:position(Vector2(x, y))
    end
end

on_key = function(key, down)
    if down and key == "Space" then
        movement_enabled = not movement_enabled
    elseif down and key == "Backspace" then
        for _,b in pairs(bubbles) do
            pop_bubble(b)
        end
    end
end

if not initialized then
    initialized = true
    -- Globals initialized here!
    bubbles = {}
    pop_effects = {}
    movement_enabled = true
    shaders = {}
    cursor_bubble = false

    -- Any more globals is an error!
    lock_global_table()

    shaders.pop = PoppingShader:new()
    shaders.bubble = BubbleShader:new()
    shaders.bg = BgShader:new(shaders.bubble)

    for i=1, ELASTICBUBBLES.STARTING_BUBBLE_COUNT do
        add_bubble(shaders.bubble:create_bubble(random_color(), random_position(), random_velocity(), random_radius()))
    end
end
