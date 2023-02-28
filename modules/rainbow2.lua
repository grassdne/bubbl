Title "🌈 2"

local COLORS = {
    Color.hex "#ff0000",
    Color.hex "#ffa500",
    Color.hex "#ffff00",
    Color.hex "#008000",
    Color.hex "#0000ff",
    Color.hex "#4b0082",
    Color.hex "#ee82ee",
}
local SIZE = 100
local DELTA_OFFSET = 2
local N = #COLORS
local MAX_PERCENT = 0.9
local MIN_PERCENT = 0.1

local offset = 0

local CircularIndex = function(tbl, i)
    return tbl[((i - 1) % #tbl) + 1]
end

OnUpdate = function(dt)
    local start_x = window_width/2 - (N / 2) * SIZE*2 - SIZE

    offset = offset + DELTA_OFFSET * dt;
    local start_i, percent_trans = math.modf(offset)
    if percent_trans > MAX_PERCENT then
        start_i = start_i + 1
        percent_trans = percent_trans - MAX_PERCENT
    end
    if percent_trans < MIN_PERCENT then
        percent_trans = percent_trans + MIN_PERCENT
    end
    for i = 1, N do
        local color = CircularIndex(COLORS, i - start_i)
        local next_color = CircularIndex(COLORS, i - start_i - 1)
        RenderSimple(Vector2(start_x + i * SIZE*2, window_height/2), color, SIZE,
            next_color, PI, percent_trans)
    end
end

LockTable(_G)
