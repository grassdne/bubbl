Title "Swirl"

local PI = math.pi
local sin, cos = math.sin, math.cos

local SIZE = 13
local PERIOD = 2
local RING_SPACING = 120
local COUNT_PER_RING = 100
local DELTA_SIZE = 0.01
local LIGHTNESS = 0.4
local SATURATION = 1.0

local delta_theta = 2*PI / COUNT_PER_RING
local delta_radius = RING_SPACING / COUNT_PER_RING

OnUpdate = function(dt)
    local theta = Seconds() * 2*PI / PERIOD
    local radius = 0
    local center = Vector2(window_width / 2, window_height / 2)
    -- greatest distance from center on the screen
    local max_dist = center:length()
    local count = max_dist / delta_radius
    local size = SIZE
    for i=1, count do
        radius = radius + delta_radius
        theta = theta + delta_theta
        size = size + DELTA_SIZE

        local pos = center + Vector2(cos(theta), sin(theta)):scale(radius)
        local color = Color.hsl(math.deg(theta), SATURATION, LIGHTNESS)
        RenderSimple(pos, color, size)
    end
end
