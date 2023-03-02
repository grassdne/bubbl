Title "Swirl"

local GENERATE_FRAMES = false

local sin, cos, deg, atan2 = math.sin, math.cos, math.deg, math.atan2

local SIZE = 13
local PERIOD = 2
local RING_SPACING = 120
local COUNT_PER_RING = 100
local DELTA_SIZE = 0.01
local LIGHTNESS = 0.4
local SATURATION = 1.0

local delta_theta = 2*PI / COUNT_PER_RING
local delta_radius = RING_SPACING / COUNT_PER_RING

local Render = function(theta)
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


local bg_width, bg_height = 512, 512
local background = CreateCanvas(bg_width, bg_height)
OnStart = function()
    for y=0, bg_height-1 do
        for x=0, bg_width-1 do
            local theta = atan2(y - bg_height/2, x - bg_width/2)
            background:set(x, y, Color.hsl(deg(theta), 1, 0.5, 0.5))
        end
    end
end

if GENERATE_FRAMES then
    local FPS = 45
    local frames_count = FPS * PERIOD
    local i = 0
    OnUpdate = function()
        Render(i/frames_count * 2*PI)
        if i < frames_count then
            Screenshot(string.format("frame_%003d.png", i))
            i = i + 1
        end
    end
else
    OnUpdate = function()
        background:draw()
        Render(Seconds() * 2*PI / PERIOD)
    end
end

LockTable(_G)
