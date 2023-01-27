title = "SVG Editor"

circles = {}
local circle_dragging
local BASE_SIZE = 20

local TextRenderer = require "textrenderer"
local Draw = require "draw"

local get_draw_box_base_position = function ()
    local center = Vector2(window_width/2, window_height/2)
    return Vector2(center.x - SVG_SIZE/2, center.y - SVG_SIZE/2)
end

local Circle = {
    new = function (self, pos, color, radius, is_focused)
        local c = setmetatable({}, self)
        c:absolute_position(pos)
        c.radius = radius
        c.color = color
        c.focused = is_focused
        return c
    end,
    absolute_position = function (self, pos)
        local base = get_draw_box_base_position()
        if pos then self.pos = pos - base end
        return base + self.pos
    end
}
Circle.__index = Circle

on_update = function(dt)
    -- Render circles
    for _,pt in ipairs(circles) do
        if pt == circle_dragging then
            render_simple(pt:absolute_position(), pt.color, pt.radius)
        else
            render_pop(pt:absolute_position(), pt.color, pt.radius, 0)
        end
    end

    local base = get_draw_box_base_position()
    Draw.rect_outline(base.x, base.y, SVG_SIZE, SVG_SIZE)

    -- Testing text
    TextRenderer.put_string(Vector2(0,45), "HELLO? HELLO? HELLO? HELLO? ", 20)
    TextRenderer.put_string(Vector2(0,0), "ABCDEFGHIJKLMNOPQRSTUVWXYZ?", 40)
end

on_mouse_move = function(x, y)
    if circle_dragging then
        circle_dragging:absolute_position(Vector2(x, y))
    end
end

on_mouse_up = function(x, y)
    circle_dragging = nil
end

local fmt = string.format
local save_to_svg = function(file_path)
    local f = assert(io.open(file_path, 'w'))
    f:write("<?xml version=\"1.0\"?>\n")
    f:write(fmt("<svg width=\"%d\" height=\"%d\">\n", SVG_SIZE, SVG_SIZE))
    
    for i,circle in ipairs(circles) do
        local x, y = circle.pos:unpack()
        f:write(fmt("  <circle cx=\"%d\" cy=\"%d\" r=\"%d\" fill=\"%s\" />\n",
                x, SVG_SIZE - y, circle.radius, circle.color:to_hex_string()))
    end

    f:write("</svg>")
    f:close()
end

local circle_at_position = function(pos)
    local relative_pos = pos - get_draw_box_base_position()
    -- We iterate backwards to get the front circle
    for i = #circles, 1, -1 do
        if circles[i].pos:dist(relative_pos) < circles[i].radius then
            return circles[i]
        end
    end
    return nil
end

on_mouse_down = function(x, y)
    circle_dragging = circle_at_position(Vector2(x, y))
    if not circle_dragging then
        circle_dragging = Circle:new(Vector2(x, y), SVGEDITOR.COLOR, BASE_SIZE, true)
        table.insert(circles, circle_dragging)
    end
end

local KEY_DELTA_RADIUS = 2
local MIN_CIRCLE_RADIUS = 5

local circle_delta_radius = function(circle, delta)
    local new_radius = circle.radius + delta
    if new_radius > MIN_CIRCLE_RADIUS then
        circle.radius = new_radius
    end
end

on_key = function(key, is_down)
    if key == "Return" and is_down then
        save_to_svg(SVGEDITOR.FILE)
    elseif key == "Up" and is_down then
        local circle = circle_at_position(mouse_position())
        if circle then circle_delta_radius(circle, KEY_DELTA_RADIUS) end
    elseif key == "Down" and is_down then
        local circle = circle_at_position(mouse_position())
        if circle then circle_delta_radius(circle, -KEY_DELTA_RADIUS) end
    elseif key == "Backspace" and is_down and circle_dragging then
        local i = assert(array_find(circle_dragging, circles))
        table.remove(circles, i)
        circle_dragging = nil
    end
end

try_load_file = function(path)
    local f = io.open(path)
    if not f then return false end
    local center = Vector2(window_width/2, window_height/2);
    for pos, radius, color in TextRenderer.svg_iter_circles(assert(f:read("*a"))) do
        table.insert(circles, Circle:new(get_draw_box_base_position() + pos, color, radius))
    end
    f:close()
    return true
end

TextRenderer.load_glyphs()
try_load_file(SVGEDITOR.FILE)
