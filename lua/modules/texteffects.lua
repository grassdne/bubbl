local GENERATE_FRAMES = false
local PERIOD = 10
local MAX_PERIOD = 5

local VAR = {
    TEXT = "bubbl",
    POSITION = "left",
    COLOR = Color.Hsl(300, 1.0, 0.5),
    COLORING = "solid",
    TIME = 4,
    SPEED = 400,
    LIMITER = "speed",
}

local particles
local start_time
local background = CreateCanvas { { Color.Hsl(0, 1, 0.01) } }
local effect

local text = require "text"

local Effect = Parent {}

local DEFAULT_COLOR = Color.Hex "#000000"
local DEFAULT_LIFETIME = 2
local DISPERSE_TIME = 0.5

local Get = function (v, ...)
    if type(v) == "function" then return v(...) end
    return v
end

local coloring = {
    rainbow = function (dimensions, goal)
        local percent = goal.x / dimensions.x
        return Color.Hsl(percent*360, 1.0, 0.5)
    end
}

local positions = {
    left = function (dimensions, goal)
        return Vector2(math.random() * -0.1, math.random()):Scale(dimensions)
    end,
    random = function (dimensions, goal)
        return Vector2(math.random(), math.random()):Scale(dimensions)
    end,
    constant = function (dimensions, goal)
        return goal
    end,
    above = function (dimensions, goal)
        local STRETCH_Y = 2
        return Vector2(goal.x, goal.y * STRETCH_Y + goal.x)
    end,
}

local to_positions = {
    random = function (dimensions, goal)
        return Vector2(math.random(), math.random()):Scale(dimensions)
    end,
    disperse = function (dimensions, goal)
        local direction = Vector2.Angle(math.random() * 2 * PI)
        return goal + direction * resolution.y/2
    end,
    zoom = function (dimensions, goal)
        local center = dimensions / 2
        local direction = Vector2.Normalize(goal - center)
        return goal + direction * 800
    end,
    vacuum = function (dimensions, goal)
        local center = dimensions / 2
        return center
    end
}

local TimeFromSpeed = function (speed)
    return function (dimensions, initial, final)
        return Vector2.Dist(initial.position, final.position) / speed
    end
end

Effect.Build = function (self, str, opts)
    local effect = setmetatable({}, self)

    local stages = { {}, {}, {} }

    local positioner = type(opts.position) == "string"
        and assert(positions[opts.position])
        or opts.position
        or positions.random

    local colorer = type(opts.color) == "string"
                 and assert(coloring[opts.color])
                 or opts.color
                 or DEFAULT_COLOR

    effect.dimensions = opts.dimensions or resolution

    local time = opts.time
                    or opts.speed and TimeFromSpeed(opts.speed)
                    or DEFAULT_LIFETIME

    local text_particles = text.BuildParticlesWithWidth(str, effect.dimensions.x)
    local goal = Vector2(0, (effect.dimensions.y - text_particles.height) / 2)

    for i,v in ipairs(text_particles) do
        local final_position = goal + v.offset
        local color = Get(colorer or DEFAULT_COLOR, effect.dimensions, final_position)
        stages[2][i] = {
            position = final_position,
            color = color,
            radius = v.radius,
        }
        stages[1][i] = {
            position = Get(positioner, effect.dimensions, final_position),
            color = color,
            radius = 1,
        }
        stages[3][i] = {
            position = Get(to_positions.disperse, effect.dimensions, final_position),
            color = color,
            radius = 0,
        }

        stages[1][i].time = Get(time, effect.dimensions, stages[1][i], stages[2][i])
        stages[2][i].time = Get(time, effect.dimensions, stages[2][i], stages[3][i])
    end

    effect.stages = stages

    effect.initial, effect.final = unpack(stages)
    effect.initial.time = Seconds()

    return effect
end

Effect.Update = function (effect, dt)
    local time = Seconds() - effect.initial.time
    local finished_count = 0
    for i=1, #effect.initial do
        local initial = effect.initial[i]
        local final = effect.final[i]
        local t = math.min(1, time / initial.time)
        finished_count = finished_count + math.floor(t)
        local radius = Lerp(initial.radius, final.radius, t)
        local color = Lerp(initial.color, final.color, t)
        local position = Lerp(initial.position, final.position, t)
        RenderPop(position, color, radius)
    end
    if not effect.finished and finished_count == #effect.initial and effect.initial == effect.stages[1] then
        effect.finished = true
        ScheduleFn(function ()
            effect.initial, effect.final = unpack(effect.stages, 2)
            effect.initial.time = Seconds()
            effect.finished = false
        end, DISPERSE_TIME)
    end
end

Effect.Disperse = function (effect)
    effect.do_disperse = true
end

local Update = function (dt)
    background:draw()
    effect:Update(dt)
end

local BuildText = function ()
    effect = Effect:Build(VAR.TEXT, {
        color=VAR.COLORING == "solid" and VAR.COLOR or VAR.COLORING,
        position=VAR.POSITION,
        time=VAR.LIMITER == "time" and VAR.TIME or nil,
        speed=VAR.LIMITER == "speed" and VAR.SPEED or nil,
    })
    assert(effect)
end

local Disperse = function ()
    effect:Disperse()
end

return {
    title = "Text Effects",

    tweak = {
        vars = VAR,
        { id="TEXT", name="Text", type="string", callback=BuildText },
        { id="POSITION", name="From", type="options", callback=BuildText, options = {
            "left", "random", "above", "constant",
        }},
        { id="LIMITER", name="Limiter", type="options", callback=BuildText, options = {
            "time", "speed"
        } },
        { id="TIME", name="Time", type="range", min=0.25, max=6, callback=BuildText },
        { id="SPEED", name="Speed", type="range", min=50, max=2000, callback=BuildText },
        { id="COLORING", name="Coloring", type="options", callback=BuildText, options = {
            "rainbow", "solid",
        } },
        { id="COLOR", name="Solid Color", type="color", callback=BuildText },
        { id="_RESET", name="Reset", type="action", callback=BuildText },
        { id="_DISPERSE", name="Disperse", type="action", callback=Disperse },
    },

    OnStart = BuildText,
    OnWindowResize = BuildText,

    Draw = function (dt)
        Update(dt)
        -- TODO: GIFs
        -- GifAddFrame("test.gif", i, i / FPS)
    end;

    OnKey = function (key, down)
        if key == "Return" and down then
            Disperse()
        end
    end;
}
