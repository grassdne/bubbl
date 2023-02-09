title = "SVG Editor"

local scale = 1

circles = {}
local is_shift_down = false
local selection_start

local selected = {}

local BASE_SIZE = 20

local TextRenderer = require "textrenderer"
local Draw = require "draw"

local get_draw_box_base_position = function ()
    local center = Vector2(window_width/2, window_height/2)
    local width = SVG_WIDTH * scale
    local height = SVG_HEIGHT * scale
    return Vector2(center.x - width/2, center.y - height/2)
end

local NormalPosition = function (pos)
    local base = get_draw_box_base_position()
    return (pos - base):scale(1/scale)
end

local AbsolutePosition = function (pos)
    local base = get_draw_box_base_position()
    return base + pos * scale
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
        if absolute then self.pos = NormalPosition(absolute) end
        return AbsolutePosition(self.pos)
    end,
    absolute_radius = function (self, absolute)
        if absolute then self.radius = absolute / scale end
        return self.radius * scale
    end,
}
Circle.__index = Circle

local GetSelection = function()
    local mouse = NormalPosition(mouse_position())
    local x1, y1 = selection_start:unpack()
    local x2, y2 = mouse:unpack()
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end
    -- x1, y1 is bottom right
    -- x2, y2 is top left
    return x1, y1, x2, y2
end

on_update = function(dt)
    -- Render circles
    for _,pt in ipairs(circles) do
        local alpha = selected[pt] and 0.5 or 0
        render_pop(pt:absolute_position(), SVGEDITOR.COLOR, pt.radius * scale, alpha)
    end

    local base = get_draw_box_base_position()
    Draw.rect_outline(base.x, base.y, SVG_WIDTH*scale, SVG_HEIGHT*scale, WEBCOLORS.BLACK)

    if selection_start then
        local x1, y1, x2, y2 = GetSelection()
        local botleft = AbsolutePosition(Vector2(x1, y1))
        local topright = AbsolutePosition(Vector2(x2, y2))
        Draw.rect_outline(botleft.x, botleft.y, topright.x - botleft.x, topright.y - botleft.y, SVGEDITOR.COLOR)
    end

    -- Testing text
    TextRenderer.put_string(Vector2(0,60), "HELLO? HELLO? HELLO? HELLO? ", 20, SVGEDITOR.COLOR)
    TextRenderer.put_string(Vector2(0,0), "ABCDEFGHIJKLMNOPQRSTUVWXYZ?", 40, SVGEDITOR.COLOR)
end

on_mouse_move = function(x, y)
    if selection_start then
        local x1, y1, x2, y2 = GetSelection()
        selected = {}
        for _,circle in ipairs(circles) do
            local x, y = circle.pos:unpack()
            local r = circle.radius
            if x1 < x + r and x - r < x2 and y1 < y + r and y - r < y2 then
                selected[circle] = true
            end
        end
    elseif drag_start then
        local mouse = NormalPosition(Vector2(x, y))
        for circle in pairs(selected) do
            local diff = mouse - drag_start
            circle.pos = circle.pos + diff
        end
        drag_start = mouse
    end
end

local fmt = string.format
local save_to_svg = function(file_path)
    local f = assert(io.open(file_path, 'w'))
    f:write("<?xml version=\"1.0\"?>\n")
    f:write(fmt("<svg width=\"%d\" height=\"%d\">\n", SVG_WIDTH, SVG_HEIGHT))
    
    for i,circle in ipairs(circles) do
        local x, y = circle.pos:unpack()
        f:write(fmt("  <circle cx=\"%d\" cy=\"%d\" r=\"%d\" fill=\"%s\" />\n",
                x, SVG_HEIGHT - y, circle.radius, SVGEDITOR.COLOR:to_hex_string()))
    end

    f:write("</svg>")
    f:close()
end

local circle_at_position = function(pos)
    -- We iterate backwards to get the front circle
    for i = #circles, 1, -1 do
        if circles[i].pos:dist(pos) < circles[i].radius then
            return circles[i]
        end
    end
    return nil
end

on_mouse_down = function(x, y)
    local pos = NormalPosition(Vector2(x, y))
    if is_shift_down then
        selection_start = pos
    else
        local found = circle_at_position(pos)
        if found and selected[found] then
            -- Start dragging selected circles
            drag_start = pos
        elseif found then
            -- Select circle
            selected[found] = true
        elseif not next(selected) then
            -- Creating new cicle
            local circle = Circle:new(pos, BASE_SIZE, true)
            table.insert(circles, circle)
            selected = {}
        else
            selected = {}
        end
    end
end

on_mouse_up = function(x, y)
    if selection_start then
        selection_start = nil
    elseif drag_start then
        -- Finished dragging
        drag_start = nil
    end
end

local KEY_DELTA_RADIUS = 2
local MIN_CIRCLE_RADIUS = 5

local circle_delta_radius = function(circle, delta)
    local new_radius = circle.radius + delta
    circle.radius = math.max(MIN_CIRCLE_RADIUS, new_radius)
end

on_key = function(key, is_down)
    if key == "Return" and is_down then
        save_to_svg(SVGEDITOR.FILE)
    elseif key == "Up" and is_down then
        for v in pairs(selected) do
            circle_delta_radius(v, KEY_DELTA_RADIUS)
        end
    elseif key == "Down" and is_down then
        for v in pairs(selected) do
            circle_delta_radius(v, -KEY_DELTA_RADIUS)
        end
    elseif key == "Backspace" and is_down then
        for v in pairs(selected) do
            local i = assert(array_find(circles, v))
            table.remove(circles, i)
        end
        selected = {}
    elseif (key == "Left Alt" or key == "Right Alt") and is_down then
        multiselect_mode = not multiselect_mode
    elseif key == "Left Shift" or key == "Right Shift" then
        is_shift_down = is_down
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
