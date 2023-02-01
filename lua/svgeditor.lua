title = "SVG Editor"

local scale = 1

circles = {}
local selected
local is_dragging = false
local BASE_SIZE = 20

local TextRenderer = require "textrenderer"
local Draw = require "draw"

local get_draw_box_base_position = function ()
    local center = Vector2(window_width/2, window_height/2)
    local size = SVG_SIZE * scale
    return Vector2(center.x - size/2, center.y - size/2)
end

local position_from_absolute = function (pos)
    local base = get_draw_box_base_position()
    return (pos - base):scale(1/scale)
end

local Circle = {
    new = function (self, pos, radius, is_focused)
        local c = setmetatable({}, self)
        c.pos = pos
        c.radius = radius
        c.focused = is_focused
        return c
    end,
    absolute_position = function (self, absolute)
        if absolute then self.pos = position_from_absolute(absolute) end
        return get_draw_box_base_position() + self.pos*scale
    end,
    absolute_radius = function (self, absolute)
        if absolute then self.radius = absolute / scale end
        return self.radius * scale
    end,
}
Circle.__index = Circle

on_update = function(dt)
    -- Render circles
    for _,pt in ipairs(circles) do
        local alpha = pt == selected and 0.5 or 0
        render_pop(pt:absolute_position(), SVGEDITOR.COLOR, pt.radius * scale, alpha)
    end

    local base = get_draw_box_base_position()
    Draw.rect_outline(base.x, base.y, SVG_SIZE*scale, SVG_SIZE*scale, WEBCOLORS.BLACK)

    -- Testing text
    TextRenderer.put_string(Vector2(0,45), "HELLO? HELLO? HELLO? HELLO? ", 20, SVGEDITOR.COLOR)
    TextRenderer.put_string(Vector2(0,0), "ABCDEFGHIJKLMNOPQRSTUVWXYZ?", 40, SVGEDITOR.COLOR)
end

on_mouse_move = function(x, y)
    if selected then
        selected:absolute_position(Vector2(x, y))
    end
end

on_mouse_up = function(x, y)
    selected = nil
end

local fmt = string.format
local save_to_svg = function(file_path)
    local f = assert(io.open(file_path, 'w'))
    f:write("<?xml version=\"1.0\"?>\n")
    f:write(fmt("<svg width=\"%d\" height=\"%d\">\n", SVG_SIZE, SVG_SIZE))
    
    for i,circle in ipairs(circles) do
        local x, y = circle.pos:unpack()
        f:write(fmt("  <circle cx=\"%d\" cy=\"%d\" r=\"%d\" fill=\"%s\" />\n",
                x, SVG_SIZE - y, circle.radius, SVGEDITOR.COLOR:to_hex_string()))
    end

    f:write("</svg>")
    f:close()
end

local circle_at_position = function(pos)
    -- We iterate backwards to get the front circle
    for i = #circles, 1, -1 do
        if circles[i]:absolute_position():dist(pos) < circles[i]:absolute_radius() then
            return circles[i]
        end
    end
    return nil
end

on_mouse_down = function(x, y)
    selected = circle_at_position(Vector2(x, y))
    if not selected then
        selected = Circle:new(position_from_absolute(Vector2(x, y)), BASE_SIZE, true)
        table.insert(circles, selected)
    end
end

local KEY_DELTA_RADIUS = 2
local MIN_CIRCLE_RADIUS = 5

local circle_delta_radius = function(circle, delta)
    local new_radius = circle.radius + delta
    if new_radius > MIN_CIRCLE_RADIUS then
        circle:absolute_radius(new_radius)
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
    elseif key == "Backspace" and is_down and selected then
        local i = assert(array_find(selected, circles))
        table.remove(circles, i)
        selected = nil
    end
end

local ZOOM_SPEED = 0.2
local ZOOM_MIN = 0.1
local ZOOM_MAX = 10
on_mouse_wheel = function(x_scroll, y_scroll)
    scale = math.clamp(scale + ZOOM_SPEED * y_scroll, ZOOM_MIN, ZOOM_MAX)
end

try_load_file = function(path)
    local f = io.open(path)
    if not f then return false end
    local center = Vector2(window_width/2, window_height/2);
    for pos, radius in TextRenderer.svg_iter_circles(assert(f:read("*a"))) do
        table.insert(circles, Circle:new(pos, radius))
    end
    f:close()
    return true
end

TextRenderer.load_glyphs()
try_load_file(SVGEDITOR.FILE)
package.loaded.svgeditor = false
