local POINT_SIZE=3

local draw = {}

draw.point = function(x, y)
    render_pop(Vector2(x, y), Color.hex "000000", POINT_SIZE, 0)
end
draw.horiz_line = function(x1, y1, w)
    for x=x1, x1+w, POINT_SIZE do draw.point(x,y1) end
end
draw.vert_line = function(x1, y1, w)
    for y=y1, y1+w, POINT_SIZE do draw.point(x1,y) end
end

draw.rect_outline = function(x1, y1, w, h)
    draw.horiz_line(x1, y1, w)
    draw.horiz_line(x1, y1+h, w)
    draw.vert_line(x1, y1, h)
    draw.vert_line(x1+w, y1, h)
end

return draw
