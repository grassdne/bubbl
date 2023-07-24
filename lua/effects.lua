local text = require "text"

local Effect = Parent {}

local DEFAULT_COLOR = Color.Hex "#000000"
local DEFAULT_LIFETIME = 2

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
local interpolator = require "anim"

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
    effect.anim = interpolator.Build(effect.stages[1], effect.stages[2])

    return effect
end

Effect.Update = function (effect, dt)
    local time
    for i, position, color, radius in effect.anim:Interpolate(time) do
        RenderPop(position, color, radius)
    end
    if effect.anim:IsComplete() and effect.do_disperse and effect.anim.initial == effect.stages[1] then
        effect.anim = interpolator.Build(effect.stages[2], effect.stages[3])
    end
end

Effect.Disperse = function (effect)
    effect.do_disperse = true
end

return Effect
