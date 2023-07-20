-- Draw lines and shapes with a bunch o' circles!

local POINT_SIZE=3

local draw = {}

draw.Point = function(x, y, color)
    RenderPop(Vector2(x, y), color or Color.hex "000000", POINT_SIZE)
end
draw.HorizontalLine = function(x1, y1, w, c)
    for x=x1, x1+w, POINT_SIZE do draw.Point(x, y1, c) end
end
draw.VerticalLine = function(x1, y1, w, c)
    for y=y1, y1+w, POINT_SIZE do draw.Point(x1, y, c) end
end

draw.Line = function(x1, y1, x2, y2, color)
    local vector = Vector2(x2-x1, y2-y1)
    local angle = vector:normalize()
    local count = vector:length() / POINT_SIZE
    for i = 0, count-1 do
        local pos = Vector2(x1, y1) + angle * (i * POINT_SIZE)
        draw.Point(pos.x, pos.y, color)
    end
    local diff_x = (x2 - x1) / POINT_SIZE
end

draw.RectOutline = function(x1, y1, w, h, c)
    -- Bottom
    draw.HorizontalLine(x1, y1, w, c)
    -- Top
    draw.HorizontalLine(x1, y1+h, w, c)
    -- Left
    draw.VerticalLine(x1, y1, h, c)
    -- Right
    draw.VerticalLine(x1+w, y1, h, c)
end

return draw
