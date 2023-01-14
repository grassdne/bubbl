title = "🌈🌈🌈"

local SPEED = 4
local MIN_RADIUS = 13
local MAX_RADIUS = 28
local MAX_ATTAINED_RADIUS = 50
local SPACING = 30
local START_POS_RIGHT = 3 * SPACING
local END_POS_LEFT = -3 * SPACING
local MOUSE_EFFECT_RADIUS = 350
local DELTA_RADIUS = 30
local ffi = require "ffi"

pop = PoppingShader:new()
particles = {}

local Particle = {
    new = function (Self, pos, color, radius)
        local p = setmetatable({}, Self)
        p.id = pop:create_particle(pos, color, radius)
        p.origin_color = color
        p.origin_radius = radius
        return p
    end;
}

local clear_particles = function ()
    for _,part in ipairs(particles) do
        pop:destroy_particle(part.id)
    end
    particles = {}
end

local gen_particles = function ()
    for x=END_POS_LEFT+SPACING, window_width + START_POS_RIGHT, SPACING do
        for i=0, window_height / SPACING do
            local radius = random.minmax(MIN_RADIUS, MAX_RADIUS)
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
        local ent = pop:get_particle(part.id);
        ent.pos.x = ent.pos.x - window_width/SPEED * dt
        if ent.pos.x < END_POS_LEFT then
            ent.pos.x = window_width+START_POS_RIGHT
            ent.pos.y = window_height * math.random()
            ent.radius = random.minmax(MIN_RADIUS, MAX_RADIUS)
            ent.color = part.origin_color
            ent.radius = part.origin_radius
        end
    end
    pop:draw(dt)

    local mouse = mouse_position()
    if mouse.x > 0 and mouse.x < window_width and mouse.y > 0 and mouse.y < window_height then
        for _,part in ipairs(particles) do
            local ent = pop:get_particle(part.id);
            local distsq = mouse:distsq(ent.pos)
            if distsq < MOUSE_EFFECT_RADIUS*MOUSE_EFFECT_RADIUS then
                local proximity = 1 - math.sqrt(distsq) / MOUSE_EFFECT_RADIUS
                ent.radius = math.min(MAX_ATTAINED_RADIUS, ent.radius + DELTA_RADIUS * proximity * dt)
            end
        end
    end
end

on_mouse_move = function(x, y)
end

on_mouse_up = function()
end

on_mouse_down = function()
end

on_key = function(key, down)
end

on_window_resize = function(w, h)
    clear_particles()
    gen_particles()
end
