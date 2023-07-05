Title "Text Effects"

local Text = require "textrenderer"

-- Let's experiment with working with normalized [0, 1] coordinates

local TEXT = "Congratuations"
local PERIOD = 10
local MAX_PERIOD = 5


local goal = Vector2(0, 0.5)
local color = Color.hsl(0, 1.0, 0)
local particles

OnStart = function ()
    particles = Text.build_particles_with_width(TEXT, 1)
    for i, pt in ipairs(particles) do
        pt.position = Vector2(math.random()/10, math.random())
        pt.goal = goal + pt.offset
        pt.delta = (pt.goal - pt.position):normalize() / MAX_PERIOD
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
        UpdatePosition(pt, dt)
        RenderPop(pt.position:scale(resolution), color, pt.radius * resolution.x, 0)
    end
end

LockTable(_G)
