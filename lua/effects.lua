local text = require "text"

local Effect = Parent {}

local DEFAULT_COLOR = Color.Hex "#000000"
local DEFAULT_LIFETIME = 2

local Get = function (v, ...)
    if type(v) == "function" then return v(...) end
    return v
end

local coloring = {
    rainbow = function (pt)
        local percent = pt.goal.x / pt.effect.dimensions.x
        return Color.Hsl(percent*360, 1.0, 0.5)
    end
}

local positions = {
    left = function (pt)
        return Vector2(math.random() * -0.1, math.random()):Scale(pt.effect.dimensions)
    end,
    random = function (pt)
        return Vector2(math.random(), math.random()):Scale(pt.effect.dimensions)
    end,
    constant = function (pt)
        return pt.goal
    end,
    above = function (pt)
        local STRETCH_Y = 8
        return Vector2(pt.goal.x, pt.goal.y + pt.offset.y * STRETCH_Y + pt.offset.x)
    end,
}

local LifetimeFromSpeed = function (speed)
    return function (pt)
        return Vector2.Dist(pt.position, pt.goal) / speed
    end
end

Effect.Build = function (self, str, opts)
    local effect = setmetatable({}, self)
    effect.dimensions = opts.dimensions or resolution
    effect.particles = text.BuildParticlesWithWidth(str, effect.dimensions.x)
    effect.color = type(opts.color) == "string"
                 and assert(coloring[opts.color])
                 or opts.color
                 or DEFAULT_COLOR
    effect.lifetime = opts.lifetime
                    or opts.speed and LifetimeFromSpeed(opts.speed)
                    or DEFAULT_LIFETIME
    effect.position = type(opts.position) == "string"
                    and assert(positions[opts.position])
                    or opts.position
                    or positions.random

    for i, pt in ipairs(effect.particles) do
        local goal = Vector2(0, (effect.dimensions.y - effect.particles.height) / 2)
        pt.goal = goal + pt.offset
        pt.effect = effect
        pt.color = Get(effect.color or DEFAULT_COLOR, pt)
        pt.position = Get(effect.position, pt)
        pt.lifetime = Get(effect.lifetime, pt)
        pt.delta = (pt.goal - pt.position) / pt.lifetime
    end

    effect.start_time = Seconds()
    return effect
end

Effect.Update = function (effect, dt)
    local time = Seconds() - effect.start_time
    for _,pt in ipairs(effect.particles) do
        if time < pt.lifetime then
            pt.position = pt.position + pt.delta * dt
        else
            pt.position = pt.goal
        end
        RenderBubble(pt.position, pt.color, pt.radius)
    end
end

return Effect
