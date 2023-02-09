local POINT_SIZE=3

local draw = {}

draw.point = function(x, y, color)
    RenderPop(Vector2(x, y), color or Color.hex "000000", POINT_SIZE, 0)
end
draw.horiz_line = function(x1, y1, w, c)
    for x=x1, x1+w, POINT_SIZE do draw.point(x, y1, c) end
end
draw.vert_line = function(x1, y1, w, c)
    for y=y1, y1+w, POINT_SIZE do draw.point(x1, y, c) end
end

draw.rect_outline = function(x1, y1, w, h, c)
    -- Bottom
    draw.horiz_line(x1, y1, w, c)
    -- Top
    draw.horiz_line(x1, y1+h, w, c)
    -- Left
    draw.vert_line(x1, y1, h, c)
    -- Right
    draw.vert_line(x1+w, y1, h, c)
end

return draw
