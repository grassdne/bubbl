-- Draw lines and shapes with a bunch o' circles!

local POINT_SIZE=3

local draw = {}

draw.Point = function(position, color)
    RenderPop(position, color or Color.Hex "000000", POINT_SIZE)
end

draw.HorizontalLine = function(start, length, c)
    for x=start.x, start.x + length, POINT_SIZE do
        draw.Point(Vector2(x, start.y), c)
    end
end

draw.VerticalLine = function(start, length, c)
    for y=start.y, start.y + length, POINT_SIZE do
        draw.Point(Vector2(start.x, y), c)
    end
end

draw.Line = function(p1, p2, color)
    local vector = p2 - p1
    local angle = vector:Normalize()
    local count = vector:Length() / POINT_SIZE
    for i = 0, count-1 do
        local pos = p1 + angle * (i * POINT_SIZE)
        draw.Point(pos, color)
    end
    local diff_x = (p2.x - p1.x) / POINT_SIZE
end

draw.RectOutline = function(position, w, h, c)
    -- Bottom
    draw.HorizontalLine(position, w, c)
    -- Top
    draw.HorizontalLine(position + Vector2(0, h), w, c)
    -- Left
    draw.VerticalLine(position, h, c)
    -- Right
    draw.VerticalLine(position + Vector2(w, 0), h, c)
end

return draw
