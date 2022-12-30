local ffi = require "ffi"
local C = ffi.C

title = "Elastic Bubbles"

TWEAK = {
    STARTING_BUBBLE_COUNT = 10,
    BUBBLE_SPEED_BASE = 150,
    BUBBLE_SPEED_VARY = 200,
    BUBBLE_RAD_BASE = 30,
    BUBBLE_RAD_VARY = 25,
    MAX_GROWTH = 200,
    MIN_GROWTH_RATE = 50,
    MAX_GROWTH_RATE = 225,
}

local growing_bubble

local add_bubble = function (bubble)
    bubbles[bubble.id] = bubble;
end

randomsign = function()
    return math.random() > 0.5 and 1 or -1
end

vary = function (base, vary)
    return base + vary * math.random()
end

local random_velocity = function()
    return Vector2(randomsign() * vary(TWEAK.BUBBLE_SPEED_BASE, TWEAK.BUBBLE_SPEED_VARY),
    randomsign() * vary(TWEAK.BUBBLE_SPEED_BASE, TWEAK.BUBBLE_SPEED_VARY))
end

local random_radius = function()
    return TWEAK.BUBBLE_RAD_BASE + math.random() * TWEAK.BUBBLE_RAD_VARY
end

local random_position = function() return Vector2(math.random()*window_width, math.random()*window_height) end

local pop_bubble = function(bubble)
    shaders.pop:create_pop(bubble.C.pos, bubble.C.color, bubble.C.rad)
    shaders.bubble:destroy_bubble(bubble.id)
    bubbles[bubble.id] = nil
end

local is_collision = function (a, b)
    local mindist = a.C.rad + b.C.rad
    return a ~= b and Vector2.distsq(a.C.pos, b.C.pos) < mindist*mindist
end

local swap_velocities = function (a, b)
    local av = Vector2(a.C.v)
    local bv = Vector2(b.C.v)
    a.C.v = bv
    b.C.v = av
end

local separate_bubbles = function (a, b)
    -- Push back bubble a so it is no longer colliding with b
    local dir_b_to_a = Vector2.normalize(a.C.pos - b.C.pos)
    local mindist = b.C.rad + a.C.rad + 1
    a.C.pos = b.C.pos + dir_b_to_a * mindist
end

minmax = function(x, min, max) return math.min(max, math.max(min, x)) end

local ensure_bubble_in_bounds = function (bubble)
    bubble.C.pos.x = minmax(bubble.C.pos.x, bubble.C.rad, window_width   - bubble.C.rad)
    bubble.C.pos.y = minmax(bubble.C.pos.y, bubble.C.rad, window_height  - bubble.C.rad)
end

local collect_all_bubbles = function ()
    local all_bubbles = {}
    if growing_bubble then table.insert(all_bubbles, growing_bubble) end
    for _, b in pairs(bubbles) do table.insert(all_bubbles, b) end
    return all_bubbles
end

local get_bubble_ids_for_bgshader = function ()
    local all_bubbles = collect_all_bubbles()
    table.sort(all_bubbles, function(a, b) return a.C.rad > b.C.rad end)
    local ids = {}
    for i=1, math.min(#all_bubbles, BGSHADER_MAX_ELEMS) do 
        ids[i] = all_bubbles[i].id
    end
    return ids
end

on_update = function(dt)
    -- Grow bubble under mouse
    if growing_bubble then
        local percent_complete = growing_bubble.C.rad / TWEAK.MAX_GROWTH
        local growth_rate = percent_complete * (TWEAK.MAX_GROWTH_RATE - TWEAK.MIN_GROWTH_RATE) + TWEAK.MIN_GROWTH_RATE
        growing_bubble:delta_radius(growth_rate * dt)
        ensure_bubble_in_bounds(growing_bubble)
        if growing_bubble.C.rad > TWEAK.MAX_GROWTH then
            pop_bubble(growing_bubble)
            growing_bubble = nil
        end
    end
    -- Move bubbles
    for _, bubble in pairs(bubbles) do
        assert(bubble ~= growing_bubble)
        if movement_enabled then
            local next = bubble.C.pos + bubble.C.v:scale(dt)
            local max_y = window_height - bubble.C.rad
            local max_x = window_width - bubble.C.rad
            if next.x < bubble.C.rad or next.x > max_x then
                bubble.C.v.x = -bubble.C.v.x
            end
            if next.y < bubble.C.rad or next.y > max_y then
                bubble.C.v.y = -bubble.C.v.y
            end
            bubble.C.pos = next
        end
        ensure_bubble_in_bounds(bubble)
    end
    -- Handle collisions
    for _, a in pairs(bubbles) do
        for _, b in pairs(bubbles) do
            if is_collision(a, b) then
                swap_velocities(a, b)
                separate_bubbles(a, b)
            end
        end
        if growing_bubble and is_collision(a, growing_bubble) then
            -- Should colliding bubbles bounce backwards?
            --a.C.v = -a.C.v
            separate_bubbles(a, growing_bubble)
        end
    end

    -- Draw bubbles!
    shaders.bg:draw(get_bubble_ids_for_bgshader())
    shaders.pop:draw(dt)
    shaders.bubble:draw()
end

local bubble_at_point = function (pos)
    for id, b in pairs(bubbles) do
        if pos:dist(b.C.pos) < b.C.rad then
            return b
        end
    end
end

on_mouse_down = function(x, y)
    if growing_bubble then return end
    local bubble = bubble_at_point(Vector2(x, y))
    if bubble then
        pop_bubble(bubble)
    else
        growing_bubble = shaders.bubble:create_bubble(Color.random(), Vector2(x, y), random_velocity(), random_radius())
    end
end

on_mouse_up = function(x, y)
    if growing_bubble then
        add_bubble(growing_bubble)
        growing_bubble = nil
    end
end

on_mouse_move = function(x, y)
    if growing_bubble then
        growing_bubble.C.pos = Vector2(x, y)
    end
end

on_key = function(key, down)
    if down and key == KEY_SPACE then
        movement_enabled = not movement_enabled
    elseif down and key == KEY_BACKSPACE then
        for _,b in pairs(bubbles) do
            pop_bubble(b)
        end
    end
end

if not initialized then
    initialized = true
    -- Do stuff here!
    bubbles = {}
    growing_bubble = nil
    movement_enabled = true
    shaders = {}
    shaders.bubble = create_bubble_shader()
    shaders.pop = create_pop_shader()
    shaders.bg = create_bg_shader(shaders.bubble)

    for i=1, TWEAK.STARTING_BUBBLE_COUNT do
        add_bubble(shaders.bubble:create_bubble(Color.random(), random_position(), random_velocity(), random_radius()))
    end
end
