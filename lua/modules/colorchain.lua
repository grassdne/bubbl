local COLORS = {
    Color.Hex "#ff0000",
    Color.Hex "#ffa500",
    Color.Hex "#ffff00",
    Color.Hex "#008000",
    Color.Hex "#0000ff",
    Color.Hex "#4b0082",
    Color.Hex "#ee82ee",
}
local SIZE = 100
local BREADTH = SIZE * 2 * 0.8
local DELTA_OFFSET = 1
local N = #COLORS

local offset = 0

local CircularIndex = function(tbl, i)
    return tbl[((i - 1) % #tbl) + 1]
end

return {
    title = "🌈 2",
    Draw = function(dt)
        local start_x = resolution.x/2 - (N / 2) * BREADTH - SIZE

        offset = offset + DELTA_OFFSET * dt;
        local start_i, percent_trans = math.modf(offset)
        for i = 1, N do
            local color = CircularIndex(COLORS, i - start_i)
            local next_color = CircularIndex(COLORS, i - start_i - 1)
            RenderTransBubble(Vector2(start_x + i * BREADTH, resolution.y/2), color, SIZE,
                next_color, Vector2(-1,0), percent_trans)
        end
    end
}
