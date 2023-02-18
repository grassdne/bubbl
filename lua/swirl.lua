title = "Swirl"
local ffi = require 'ffi'

local SIZE = 13
local PERIOD = 5
local DELTA_RADIUS = 1
local DELTA_THETA = 0.07
local LIGHTNESS = 0.4
local SATURATION = 1.0
local PI = math.pi

local sin, cos = math.sin, math.cos
OnUpdate = function()
    local theta = ffi.C.get_time() * 2*PI / PERIOD
    local radius = 0
    local center = Vector2(window_width / 2, window_height / 2)
    local max_dist = Vector2(window_width, window_height):length() / 2
    local count = max_dist / DELTA_RADIUS
    local size = SIZE
    for i=1, count do
        radius = radius + DELTA_RADIUS
        theta = theta + DELTA_THETA
        size = size + 0.01

        local pos = center + Vector2(cos(theta), sin(theta)):scale(radius)
        local color = Color.hsl(math.deg(theta), SATURATION, LIGHTNESS)
        RenderSimple(pos, color, size, nil)
    end
end
