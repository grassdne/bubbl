local Text = require "text"

local GENERATE_FRAMES = false
local PERIOD = 10
local MAX_PERIOD = 5

local COLOR = Color.hsl(300, 1.0, 0.5)

local VAR = {
    TEXT = "bubbl",
    EFFECT = "coalesce",
}

local EFFECTS = {
    in_from_left = {
        position = function (pt)
            return Vector2(math.random() * -0.1, math.random()):scale(resolution)
        end,
        delta = function (pt)
            local MAX_TIME = 5
            return (pt.goal - pt.position):normalize() * resolution.x / MAX_TIME
        end,
        length=7,
    },
    coalesce = {
        position = function ()
            return Vector2(math.random(), math.random()):scale(resolution)
        end,
        delta = function (pt)
            local TIME = 5
            return (pt.goal - pt.position) / TIME
        end,
        color = function (pt)
            do return Color.hsl(300, 1.0, 0.5) end
            local percent = pt.goal.x / resolution.x
            return Color.hsl(percent*360, 1.0, 0.5)
        end,
        length=7,
    },
    pour = {
        position = function (pt)
            local STRETCH_Y = 8
            return Vector2(pt.goal.x, pt.goal.y + pt.offset.y * STRETCH_Y + pt.offset.x)
        end,
        delta = function (pt)
            local MAX_TIME = 5
            return (pt.goal - pt.position):normalize() * resolution.x / MAX_TIME
        end,
        length=20,
    }
}

local particles

local background = CreateCanvas { { Color.hsl(0, 1, 0.01) } }

local UpdatePosition = function (point, dt)
    local next_position = point.position + point.delta * dt
    local diff = point.goal - point.position
    if diff.x * point.delta.x > 0 or diff.y * point.delta.y > 0 then
        point.position = next_position
    else
        point.position = point.goal
    end
end

local Update = function (dt)
    background:draw()
    local finished_count = 0
    for _,pt in ipairs(particles) do
        UpdatePosition(pt, dt)
        if pt.goal == pt.position then finished_count = finished_count + 1 end
        RenderSimple(pt.position, pt.color, pt.radius)
    end
    return finished_count < #particles
end

local effect

local BuildText = function ()
    effect = EFFECTS[VAR.EFFECT]

    particles = Text.build_particles_with_width(VAR.TEXT, resolution.x)
    local goal = Vector2(0, (resolution.y - particles.height) / 2)

    for i, pt in ipairs(particles) do
        pt.goal = goal + pt.offset
        pt.position = effect.position(pt)
        pt.delta = effect.delta(pt)
        pt.color = effect.color and effect.color(pt) or COLOR
    end
end

return {
    title = "Text Effects",

    tweak = {
        vars = VAR,
        { id="TEXT", name="Text", type="string", callback=BuildText },
        { id="EFFECT", name="Effect", type="options", callback=BuildText, options = { "in_from_left", "coalesce", "pour" } },
    },

    OnStart = BuildText,

    Draw = function (dt)
        Update(dt)
        -- TODO: GIFs
        -- GifAddFrame("test.gif", i, i / FPS)
    end,
}
