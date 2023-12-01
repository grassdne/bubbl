local SVGEDITOR = {
    FILE = arg[2] or "img.svg",
    COLOR = WEBCOLORS.PURPLE,
}

local scale = 1

local circles = {}
local is_shift_down = false
local is_ctrl_down = false
local is_a_down = false
local selection_start
local drag_start
local rotate = nil

local selected = {}

local BASE_SIZE = 20
local KEY_MOVEMENT = 20
local KEY_LITTLE_MOVEMENT = 5

local TextRenderer = require "text"
local draw = require "draw"
local glyph_height = TextRenderer.GLYPH_HEIGHT
local glyph_width = 135 -- default

local get_draw_box_base_position = function ()
    local center = resolution / 2
    local width = glyph_width * scale
    local height = glyph_height * scale
    return Vector2(center.x - width/2, center.y - height/2)
end

local NormalPosition = function (pos)
    local base = get_draw_box_base_position()
    return (pos - base) * (1/scale)
end

local AbsolutePosition = function (pos)
    local base = get_draw_box_base_position()
    return base + pos * scale
end

local Circle = {
    New = function (self, pos, radius, is_focused)
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
    local mouse = NormalPosition(MousePosition())
    local x1, y1 = selection_start:Unpack()
    local x2, y2 = mouse:Unpack()
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end
    -- x1, y1 is bottom right
    -- x2, y2 is top left
    return x1, y1, x2, y2
end

local Draw = function(dt)
    -- Render circles
    for _,pt in ipairs(circles) do
        local color = Color(SVGEDITOR.COLOR)
        color.a = selected[pt] and 0.5 or 1
        RenderPop(pt:absolute_position(), color, pt.radius * scale)
    end

    local base = get_draw_box_base_position()
    draw.RectOutline(base, glyph_width*scale, glyph_height*scale, WEBCOLORS.BLACK)

    if selection_start then
        local x1, y1, x2, y2 = GetSelection()
        local botleft = AbsolutePosition(Vector2(x1, y1))
        local topright = AbsolutePosition(Vector2(x2, y2))
        draw.RectOutline(botleft, topright.x - botleft.x, topright.y - botleft.y, SVGEDITOR.COLOR)
    end

     if rotate then
         local axis = AbsolutePosition(rotate.axis_position)
         local mouse = MousePosition()
         draw.Line(axis, mouse, SVGEDITOR.COLOR)
     end

    -- Testing text
    if is_a_down then
        local y = 0
        for _,str in ipairs{"over the lazy dog", "the quick brown fox jumps"} do
            local height = TextRenderer.PutstringWithWidth(Vector2(0,y), str, resolution.x, SVGEDITOR.COLOR)
            y = y + height
        end
    end
end

local fmt = string.format
local SaveToSVG = function(file_path)
    local f = assert(io.open(file_path, 'w'))
    f:write("<?xml version=\"1.0\"?>\n")
    f:write(fmt("<svg width=\"%d\" height=\"%d\">\n", glyph_width, glyph_height))
    
    for i,circle in ipairs(circles) do
        local x, y = circle.pos:Unpack()
        if x > 0 and x < glyph_width and y > 0 and y < glyph_height then
            f:write(fmt("  <circle cx=\"%d\" cy=\"%d\" r=\"%d\" fill=\"%s\" />\n",
                    x, glyph_height - y, circle.radius, SVGEDITOR.COLOR:ToHexString()))
        end
    end

    f:write("</svg>")
    f:close()
end

local circle_at_position = function(pos)
    -- We iterate backwards to get the front circle
    for i = #circles, 1, -1 do
        if circles[i].pos:Dist(pos) < circles[i].radius then
            return circles[i]
        end
    end
    return nil
end

local FindSelectionCenterPoint = function()
    local right = 0
    local left = resolution.x
    local top = 0
    local bottom = resolution.y
    for circle in pairs(selected) do
        local pos = circle:absolute_position()
        left = math.min(left, pos.x)
        right = math.max(right, pos.x)
        top = math.max(top, pos.y)
        bottom = math.min(bottom, pos.y)
    end
    local x = (left + right) / 2
    local y = (bottom + top) / 2
    return NormalPosition(Vector2(x, y))
end

local MIN_CIRCLE_RADIUS = 5

local circle_delta_radius = function(circle, delta)
    local new_radius = circle.radius + delta
    circle.radius = math.max(MIN_CIRCLE_RADIUS, new_radius)
end

local ZOOM_SPEED = 0.2
local ZOOM_MIN = 0.1
local ZOOM_MAX = 10

local TryLoadFile = function(path)
    local f = io.open(path)
    if not f then
        print("Did not find file "..path)
        return false
    end
    local center = resolution / 2
    local content = f:read("*a")
    glyph_width, glyph_height = TextRenderer.SvgGetSize(content)
    for pos, radius in TextRenderer.SvgIterCircles(content) do
        table.insert(circles, Circle:New(pos, radius))
    end
    f:close()
    return true
end

TryLoadFile(SVGEDITOR.FILE)

return {
    title = "SVG Editor",
    Draw = Draw,

    OnMouseDown = function(x, y)
        local pos = NormalPosition(Vector2(x, y))
        if is_shift_down then
            selection_start = pos
        elseif is_ctrl_down and next(selected) then
            -- Start rotation
            rotate = { start_position = pos, axis_position = FindSelectionCenterPoint() }
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
                local circle = Circle:New(pos, BASE_SIZE, true)
                table.insert(circles, circle)
                selected = {}
            else
                selected = {}
            end
        end
    end,

    OnMouseWheel = function(x_scroll, y_scroll)
        scale = math.clamp(scale + ZOOM_SPEED * y_scroll, ZOOM_MIN, ZOOM_MAX)
    end,

    OnKey = function(key, is_down)
        if key == "Return" and is_down then
            SaveToSVG(SVGEDITOR.FILE)
        elseif key == "Backspace" and is_down then
            for v in pairs(selected) do
                local i = assert(ArrayFind(circles, v))
                table.remove(circles, i)
            end
            selected = {}
        elseif key == "Left Shift" or key == "Right Shift" then
            is_shift_down = is_down
        elseif key == "Left Ctrl" or key == "Right Ctrl" then
            is_ctrl_down = is_down
        elseif key == "C" and is_down then
            local new_selected = {}
            local OFFSET = Vector2(BASE_SIZE, BASE_SIZE)
            for v in pairs(selected) do
                local new_circle = Circle:New(v.pos + OFFSET, v.radius, true)
                table.insert(circles, new_circle)
                new_selected[new_circle] = true
            end
            selected = new_selected
        elseif is_down and next(selected) and key == "Up" then
            for circle in pairs(selected) do
                circle.pos.y = circle.pos.y + KEY_MOVEMENT
            end
        elseif is_down and next(selected) and key == "Down" then
            for circle in pairs(selected) do
                circle.pos.y = circle.pos.y - KEY_MOVEMENT
            end
        elseif is_down and next(selected) and key == "Left" then
            for circle in pairs(selected) do
                circle.pos.x = circle.pos.x - KEY_MOVEMENT
            end
        elseif is_down and next(selected) and key == "Right" then
            for circle in pairs(selected) do
                circle.pos.x = circle.pos.x + KEY_MOVEMENT
            end
        elseif key == "A" then
            is_a_down = is_down
        end
    end,

    OnMouseUp = function(x, y)
        if selection_start then
            selection_start = nil
        elseif drag_start then
            -- Finished dragging
            drag_start = nil
        elseif rotate then
            rotate = nil
        end
    end,

    OnMouseMove = function(x, y)
        local mouse = NormalPosition(Vector2(x, y))
        if selection_start then
            local x1, y1, x2, y2 = GetSelection()
            selected = {}
            for _,circle in ipairs(circles) do
                local x, y = circle.pos:Unpack()
                local r = circle.radius
                if x1 < x + r and x - r < x2 and y1 < y + r and y - r < y2 then
                    selected[circle] = true
                end
            end
        elseif drag_start then
            for circle in pairs(selected) do
                local diff = mouse - drag_start
                circle.pos = circle.pos + diff
            end
            drag_start = mouse
        elseif rotate then
            local relative_start = rotate.start_position - rotate.axis_position
            local start_angle = math.atan2(relative_start.y, relative_start.x)
            local relative_cur = mouse - rotate.axis_position
            local new_angle = math.atan2(relative_cur.y, relative_cur.x)
            local angle_delta = new_angle - start_angle
            rotate.start_position = mouse
            for circle in pairs(selected) do
                local pos = circle.pos - rotate.axis_position
                local mag = pos:Length()
                local theta = math.atan2(pos.y, pos.x)
                local new_theta = theta + angle_delta
                circle.pos = Vector2(math.cos(new_theta), math.sin(new_theta)) * mag + rotate.axis_position
            end
        end
    end,
}
