title = "🌈🌈🌈"

local SPEED = 4
local MIN_RADIUS = 10
local MAX_RADIUS = 30
local SPACING = 30

pop = PoppingShader:new()

local Particle = {
    new = function (Self, pos, color, radius)
        local p = setmetatable({}, Self)
        p.id = pop:create_particle(pos, color, radius)
        return p
    end;
}
local res = resolution()

local particles = {}

for x=0, res.x, SPACING do
    for i=0, res.y / SPACING do
        local radius = random.minmax(MIN_RADIUS, MAX_RADIUS)
        local pos = Vector2(x, res.y * math.random())
        local color = Color.hsl(x/res.x*360, 1, 0.5)
        table.insert(particles, Particle:new(pos, color, radius))
    end
end
on_update = function(dt)
    for _,part in ipairs(particles) do
        local ent = pop:get_particle(part.id);
        ent.pos.x = ent.pos.x - res.x/SPEED * dt
        if ent.pos.x < 0 then
            ent.pos.x = ent.pos.x + res.x
            ent.pos.y = res.y * math.random()
            ent.radius = random.minmax(MIN_RADIUS, MAX_RADIUS)
        end
    end
    pop:draw(dt)
end

on_mouse_move = function()
end

on_mouse_up = function()
end

on_mouse_down = function()
end

on_key = function()
end
