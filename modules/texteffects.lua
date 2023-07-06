Title "Text Effects"

local Text = require "textrenderer"

local TEXT = "bubbl"
local PERIOD = 10
local MAX_PERIOD = 5
GENERATE_FRAMES = true


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

if GENERATE_FRAMES then
    local FPS = 50
    local LENGTH = MAX_PERIOD * 1.25
    local frames_count = FPS * LENGTH
    local i = 0
    OnUpdate = function ()
        for _,pt in ipairs(particles) do
            UpdatePosition(pt, 1/FPS)
            RenderSimple(pt.position, color, pt.radius)
        end
        background:draw()
        if i < frames_count then
            GifAddFrame("logo.gif", i, i / FPS)
            i = i + 1
        else
            Quit()
        end
    end
else
    OnUpdate = function (dt)
        for _,pt in ipairs(particles) do
            UpdatePosition(pt, dt)
            RenderSimple(pt.position, color, pt.radius)
        end
        background:draw()
    end
end

LockTable(_G)
