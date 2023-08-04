local VAR = require "modules.popper.tweak"
local BUBBLE_SPAWN_ANIMATION_LENGTH = 0.1

local Bubble = Parent {
    New = function (Self, position, velocity, radius)
        local p = setmetatable({}, Self)
        p.position = position
        p.radius = radius
        p.hue = math.random()
        p.velocity = velocity
        p.birth = Seconds()
        return p
    end,
    Color = function (bubble)
        return Color.Hsl(bubble.hue*360, VAR.BUBBLE_SATURATION, VAR.BUBBLE_LIGHTNESS, 1)
    end,
    Velocity = function (bubble)
        return bubble.velocity
    end,
    Radius = function (bubble)
        local time = Seconds()
        local t = math.min(1, (time - bubble.birth) / BUBBLE_SPAWN_ANIMATION_LENGTH)
        return Lerp(0, bubble.radius, t)
    end,
    Render = function (bubble)
        RenderBubble(bubble.position, bubble:Color(), bubble:Radius())
    end,
}

return Bubble
