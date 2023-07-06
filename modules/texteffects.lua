Title "Text Effects"

local Text = require "textrenderer"

local TEXT = "bubbl"
local PERIOD = 10
local MAX_PERIOD = 5


local color = Color.hsl(300, 1.0, 0.5)
local particles

local background = CreateCanvas { { Color.hsl(0, 1, 0.01) } }

OnStart = function ()
    particles = Text.build_particles_with_width(TEXT, window_width)
    local goal = Vector2(0, (window_height - particles.height) / 2)

    for i, pt in ipairs(particles) do
        pt.position = Vector2(math.random() * -0.1, math.random()):scale(resolution)
        pt.goal = goal + pt.offset
        pt.delta = (pt.goal - pt.position):normalize() * resolution.x / MAX_PERIOD
    end
end

local UpdatePosition = function (point, dt)
    local next_position = point.position + point.delta * dt
    local diff = point.goal - point.position
    if diff.x * point.delta.x > 0 and diff.y * point.delta.y > 0 then
        point.position = next_position
    else
        point.position = point.goal
    end
end

OnUpdate = function (dt)
    for _,pt in ipairs(particles) do
    local goal = Vector2(0, (window_height - particles.height) / 2)
        UpdatePosition(pt, dt)
        RenderSimple(pt.position, color, pt.radius)
    end
    background:draw()
end

LockTable(_G)
