title = "SVG Editor"

circles = {}
local circle_dragging
local BASE_SIZE = 15

local TextRenderer = require "textrenderer"

local create_particle = function (pos, color, radius, is_focused)
    return {
        pos = pos,
        radius = radius,
        color = color,
        focused = is_focused,
    }
end

on_update = function(dt)
    -- Render circles
    for _,pt in ipairs(circles) do
        if pt == circle_dragging then
            render_simple(pt.pos, pt.color, pt.radius)
        else
            render_pop(pt.pos, pt.color, pt.radius, 0)
        end
    end

    -- Testing text
    TextRenderer.put_string(Vector2(0,0), "AAAA??", 40)
end

on_mouse_move = function(x, y)
    if circle_dragging then
        circle_dragging.pos = Vector2(x, y)
    end
end

on_mouse_up = function(x, y)
    circle_dragging = nil
end

local get_bounding_box = function ()
    -- Could be slow if we have 1 million+ circles

    assert(#circles > 0)
    local circles = table.copy(circles)

    table.sort(circles, function(a, b) return a.pos.x < b.pos.x end)
    local leftmost = circles[1].pos.x - circles[1].radius
    local rightmost = circles[#circles].pos.x + circles[#circles].radius

    table.sort(circles, function(a, b) return a.pos.y < b.pos.y end)
    local bottommost = circles[1].pos.y - circles[1].radius
    local topmost = circles[#circles].pos.y + circles[#circles].radius

    return { left=leftmost, right=rightmost, bottom=bottommost, top=topmost }
end

local get_svg_coords = function()
    local bounds = get_bounding_box()
    local width = bounds.right - bounds.left
    local height = bounds.top - bounds.bottom
    local size = math.max(width, height)
    local buffer_left = (size - width) / 2
    local buffer_bottom = (size - height) / 2
    local scale = SVG_SIZE / size
    local coords = {}
    coords.size = size
    coords.scale = scale
    for i,v in ipairs(circles) do
        local x = (v.pos.x - bounds.left + buffer_left) * scale 
        -- SVG coordinate system has top left origin
        local y = (size - (v.pos.y - bounds.bottom + buffer_bottom)) * scale
        coords[i] = Vector2(x, y)
    end
    return coords
end

local fmt = string.format
local save_to_svg = function(file_path)
    local f = assert(io.open(file_path, 'w'))
    f:write("<?xml version=\"1.0\"?>\n")
    f:write(fmt("<svg width=\"%d\" height=\"%d\">\n", SVG_SIZE, SVG_SIZE))
    
    local coords = get_svg_coords()
    for i,circle in ipairs(circles) do
        local x, y = coords[i]:unpack()
        f:write(fmt("  <circle cx=\"%d\" cy=\"%d\" r=\"%d\" fill=\"%s\" />\n",
                x, y, circle.radius * coords.scale, circle.color:to_hex_string()))
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
    circle_dragging = circle_at_position(Vector2(x, y))
    if not circle_dragging then
        circle_dragging = create_particle(Vector2(x, y), SVGEDITOR.COLOR, BASE_SIZE, true)
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

on_window_resize = function(w, h) end

try_load_file = function(path)
    local f = io.open(path)
    if not f then return false end
    local center = Vector2(window_width/2, window_height/2);
    local start_position = center - Vector2(SVG_SIZE/2, SVG_SIZE/2)
    for pos, radius, color in TextRenderer.svg_iter_circles(assert(f:read("*a"))) do
        table.insert(circles, create_particle(start_position + pos, color, radius))
    end
    f:close()
    return true
end

TextRenderer.load_glyphs()
try_load_file(SVGEDITOR.FILE)
