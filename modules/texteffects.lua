local Text = require "text"

local GENERATE_FRAMES = false
local PERIOD = 10
local MAX_PERIOD = 5


local VAR = {
    TEXT = "bubbl",
    EFFECT = "coalesce",
    COLOR = Color.Hsl(300, 1.0, 0.5),
}

-- Colors
local Rainbow = function (pt)
    local percent = pt.goal.x / resolution.x
    return Color.Hsl(percent*360, 1.0, 0.5)
end

local EFFECTS = {
    in_from_left = Parent {
        Init = function (pt)
            pt.position = Vector2(math.random() * -0.1, math.random()):Scale(resolution)
            local SPEED = 400
            pt.lifetime = Vector2.Dist(pt.position, pt.goal) / SPEED
            pt.delta = (pt.goal - pt.position) / pt.lifetime
        end,
        Update = function (pt, dt)
            pt.position = pt.position + pt.delta * dt
        end,
        Render = function (pt)
            RenderBubble(pt.position, VAR.COLOR, pt.radius)
        end,
    },
    coalesce = Parent {
        Init = function (pt)
            pt.position = Vector2(math.random(), math.random()):Scale(resolution)
            pt.lifetime = 5
            pt.color = Rainbow(pt)
            pt.delta = (pt.goal - pt.position) / pt.lifetime
        end,
        Update = function (pt, dt)
            pt.position = pt.position + pt.delta * dt
        end,
        Render = function (pt)
            RenderBubble(pt.position, pt.color, pt.radius)
        end,
    },
    pour = Parent {
        Init = function (pt)
            local STRETCH_Y = 8
            local SPEED = 300
            pt.position = Vector2(pt.goal.x, pt.goal.y + pt.offset.y * STRETCH_Y + pt.offset.x)
            pt.lifetime = (pt.position.y - pt.goal.y) / SPEED
            pt.delta = (pt.goal - pt.position) / pt.lifetime
        end,
        Update = function (pt, dt)
            pt.position = pt.position + pt.delta * dt
        end,
        Render = function (pt)
            RenderBubble(pt.position, VAR.COLOR, pt.radius)
        end,
    },
    dissolve = {
        start_position = function (pt)
            return pt.goal
        end,
        delta = function (pt)
            return Vector2(0, 0)
        end,
        color = function (pt)
            local color = Color(VAR.COLOR)
            color.a = 0
            local time = math.random() * MAX_PERIOD
            ScheduleFn(function ()
                color.a = 1
            end, time)
            return color
        end,
    },
}

local particles
local start_time
local background = CreateCanvas { { Color.Hsl(0, 1, 0.01) } }
local effect

local Update = function (dt)
    background:draw()
    local finished_count = 0
    local time = Seconds() - start_time
    for _,pt in ipairs(particles) do
        if time < pt.lifetime then
            pt:Update(dt)
        end
        pt:Render()
    end
    return finished_count < #particles
end


local BuildText = function ()
    effect = EFFECTS[VAR.EFFECT]
    particles = Text.BuildParticlesWithWidth(VAR.TEXT, resolution.x)
    local goal = Vector2(0, (resolution.y - particles.height) / 2)

    for i, pt in ipairs(particles) do
        pt.goal = goal + pt.offset
        setmetatable(pt, effect)
        pt:Init()
    end
    start_time = Seconds()
end

return {
    title = "Text Effects",

    tweak = {
        vars = VAR,
        { id="TEXT", name="Text", type="string", callback=BuildText },
        { id="EFFECT", name="Effect", type="options", callback=BuildText, options = { "in_from_left", "coalesce", "pour" } },
        { id="COLOR", name="Color", type="color", callback=BuildText },
    },

    OnStart = BuildText,

    Draw = function (dt)
        Update(dt)
        -- TODO: GIFs
        -- GifAddFrame("test.gif", i, i / FPS)
    end,
}
