local GENERATE_FRAMES = false

local sin, cos, deg, atan2 = math.sin, math.cos, math.deg, math.atan2

local SIZE = 13
local PERIOD = 2
local DELTA_SIZE = 0.01
local BG_ALPHA = 0.4

local VAR = {
    LIGHTNESS = 0.4,
    SATURATION = 1.0,
    RING_SPACING = 120,
    COUNT_PER_RING = 100,
    PARTICLE_ENTITY = "bubble",
}

local Render = function(theta)
    local delta_radius = VAR.RING_SPACING / VAR.COUNT_PER_RING
    local delta_theta = 2*PI / VAR.COUNT_PER_RING

    local radius = 0
    local center = resolution / 2
    -- greatest distance from center on the screen
    local max_dist = center:length()
    local count = max_dist / delta_radius
    local size = SIZE
    for i=1, count do
        radius = radius + delta_radius
        theta = theta + delta_theta
        size = size + DELTA_SIZE

        local pos = center + Vector2(cos(theta), sin(theta)) * radius
        local color = Color.hsl(math.deg(theta), VAR.SATURATION, VAR.LIGHTNESS)
        if VAR.PARTICLE_ENTITY == "bubble" then
            RenderSimple(pos, color, size)
        elseif VAR.PARTICLE_ENTITY == "pop" then
            RenderPop(pos, color, size, 0)
        end
    end
end

local bg_width, bg_height = 512, 512
local background = CreateCanvas(bg_width, bg_height)

local Draw
if GENERATE_FRAMES then
    local FPS = 45
    local frames_count = FPS * PERIOD
    local i = 0
    Draw = function()
        Render(i/frames_count * 2*PI)
        if i < frames_count then
            Screenshot(string.format("frame_%003d.png", i))
            i = i + 1
        end
    end
else
    Draw = function()
        background:draw()
        Render(Seconds() * 2*PI / PERIOD)
    end
end

return {
    title = "Swirl",
    tweak = {
        vars = VAR,

        { id="RING_SPACING", name="Ring Spacing", type="range", min=60, max=180 },
        { id="COUNT_PER_RING", name="Particles Per Ring", type="range", min=50, max=150 },
        { id="PARTICLE_ENTITY", name="Particle Type", type="options", options = { "bubble", "pop" } },
        { id="LIGHTNESS", name="Lightness", type="range", min=0, max=1 },
        -- Can't do much anything interesting with Saturation
        --{ id="SATURATION", name="Saturation", type="range", min=0, max=1 },
    },
    Draw = Draw,
    OnStart = function()
        for y=0, bg_height-1 do
            for x=0, bg_width-1 do
                local theta = atan2(y - bg_height/2, x - bg_width/2)
                background:set(x, y, Color.hsl(deg(theta), 1, 0.5, BG_ALPHA))
            end
        end
    end
}
