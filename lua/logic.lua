local ffi = require "ffi"
local C = ffi.C

title = "Elastic Bubbles"

TWEAK = {
    STARTING_BUBBLE_COUNT = 10,
    BUBBLE_SPEED_BASE = 150,
    BUBBLE_SPEED_VARY = 200,
    BUBBLE_RAD_BASE = 35,
    BUBBLE_RAD_VARY = 25,
    MAX_GROWTH = 200,
    GROWTH_TIME = 2,
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
    C.create_pop(bubble.C.pos, bubble.C.color, bubble.C.rad)
    C.destroy_bubble(bubble.id)
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

ensure_bubble_in_bounds = function (bubble)
    bubble.C.pos.x = minmax(bubble.C.pos.x, bubble.C.rad, window_width   - bubble.C.rad)
    bubble.C.pos.y = minmax(bubble.C.pos.y, bubble.C.rad, window_height  - bubble.C.rad)
end

on_update = function(dt)
    -- Grow bubble under mouse
    if growing_bubble then
        local delta_radius = TWEAK.MAX_GROWTH / TWEAK.GROWTH_TIME
        growing_bubble:delta_radius(delta_radius * dt)
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
end

on_mouse_down = function(x, y)
    if growing_bubble then return end
    local bubble = C.get_bubble_at_point(Vector2(x, y))
    if bubble >= 0 then
        pop_bubble(bubbles[bubble])
    else
        growing_bubble = Bubble.new(Color.random(), Vector2(x, y), random_velocity(), random_radius())
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
    end
end

if not initialized then
    initialized = true
    -- Do stuff here!
    bubbles = {}
    growing_bubble = nil
    movement_enabled = true

    for i=1, TWEAK.STARTING_BUBBLE_COUNT do
        add_bubble(Bubble.new(Color.random(), random_position(), random_velocity(), random_radius()))
    end
end
