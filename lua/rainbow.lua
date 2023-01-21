title = "🌈🌈🌈"

local START_POS_RIGHT = RAINBOW.WRAPAROUND_BUFFER * RAINBOW.SPACING
local END_POS_LEFT = -RAINBOW.WRAPAROUND_BUFFER * RAINBOW.SPACING

local ffi = require "ffi"

pop = PoppingShader:new()
particles = {}

local Particle = {
    new = function (Self, pos, color, radius)
        local p = setmetatable({}, Self)
        p.pos = pos
        p.radius = radius
        p.color = color
        p.origin_color = color
        return p
    end;
}

local clear_particles = function ()
    particles = {}
end

local gen_particles = function ()
    for x=END_POS_LEFT+RAINBOW.SPACING, window_width + START_POS_RIGHT, RAINBOW.SPACING do
        for i=0, window_height / RAINBOW.SPACING do
            local radius = random.minmax(RAINBOW.MIN_RADIUS, RAINBOW.MAX_RADIUS)
            local pos = Vector2(x, window_height * math.random())
            local color = Color.hsl(x/window_width*360, 1, 0.5)
            local pt = Particle:new(pos, color, radius)
            table.insert(particles, pt)
        end
    end
end

gen_particles()

on_update = function(dt)
    for _,part in ipairs(particles) do
        local length = window_width + START_POS_RIGHT - END_POS_LEFT
        part.pos.x = part.pos.x - length / RAINBOW.PERIOD * dt
        if part.pos.x < END_POS_LEFT then
            part.pos.x = window_width+START_POS_RIGHT
            part.pos.y = window_height * math.random()
            part.color = part.origin_color
            part.radius = random.minmax(RAINBOW.MIN_RADIUS, RAINBOW.MAX_RADIUS)
        end
        pop:render_particle(part.pos, part.color, part.radius, 1)
    end

    local mouse = mouse_position()
    if mouse.x > 0 and mouse.x < window_width and mouse.y > 0 and mouse.y < window_height then
        for _,part in ipairs(particles) do
            local distsq = mouse:distsq(part.pos)
            if distsq < RAINBOW.MOUSE_EFFECT_RADIUS*RAINBOW.MOUSE_EFFECT_RADIUS then
                local proximity = 1 - math.sqrt(distsq) / RAINBOW.MOUSE_EFFECT_RADIUS
                part.radius = math.min(RAINBOW.MAX_ATTAINED_RADIUS, part.radius + RAINBOW.SIZE_DELTA * proximity * dt)
            end
        end
    end

    pop:draw(dt)
end

on_mouse_move = function(x, y) end

on_mouse_up = function(x, y) end

on_mouse_down = function(x, y) end

on_key = function(key, down) end

on_window_resize = function(w, h)
    clear_particles()
    gen_particles()
end
