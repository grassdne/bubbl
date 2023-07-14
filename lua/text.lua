-- Render text with a bunch of circles!

local TextRenderer = {}

TextRenderer.GLYPH_WIDTH = 153
TextRenderer.GLYPH_HEIGHT = 256

local glyph_files = {
    [" "] = "_space.svg",
    ["."] = "_period.svg",
    [":"] = "_colon.svg",
    [","] = "_comma.svg",
    [";"] = "_semicolon.svg",
    ["("] = "_openparenthesis.svg",
    [")"] = "_openparenthesis.svg",
    ["["] = "_opensquarebrackets.svg",
    ["]"] = "_closesquarebrackets.svg",
    ["*"] = "_star.svg",
    ["!"] = "_exclamation.svg",
    ["?"] = "_question.svg",
    ["\'"] = "_singlequote.svg",
    ["\""] = "_doublequote.svg",
}
for a = string.byte('A'), string.byte('Z') do
    glyph_files[string.char(a)] = string.char(a)..'.svg'
end
for a = string.byte('a'), string.byte('z') do
    glyph_files[string.char(a)] = string.char(a)..'.svg'
end

local glyphs = {}


local next_svg_circle = function (get_match)
    local cx, cy, r, fill = get_match()
    if cx then
        return Vector2(tonumber(cx), TextRenderer.GLYPH_HEIGHT - tonumber(cy)),
        tonumber(r),
        Color.hex(fill)
    end
end
TextRenderer.svg_iter_circles = function (contents)
    local get_match = contents:gmatch("<circle cx=\"(%d*)\" cy=\"(%d*)\" r=\"(%d*)\" fill=\"(%#%x*)\" />")
    return next_svg_circle, get_match
end

TextRenderer.load_glyphs = function()
    for char, file in pairs(glyph_files) do
        -- TODO: support having multiple fonts
        local f = io.open("glyphs/Liberation Mono/"..file)
        if f then
            local contents = f:read("*a")
            local circles = {}
            for pos, radius, color in TextRenderer.svg_iter_circles(contents) do
                table.insert(circles, {
                    pos=pos,
                    radius=radius,
                })
            end
            circles.width, circles.height = contents:match("<svg width=\"(%d+)\" height=\"(%d+)\">")
            if not circles.width or not circles.height then print("WARNING: "..file.." missing svg dimensions") end
            glyphs[char] = circles
            f:close()
        end
    end
end

local Glyph = function (char) return glyphs[char] or glyphs[' '] end

local put_char_with_scale = function (pos, char, scale, color)
    local circles = Glyph(char)
    for _,circle in ipairs(circles) do
        RenderPop(
            circle.pos * scale + pos,
            color or WEBCOLORS.BLACK,
            circle.radius * scale,
            0
        )
    end
end

---@param pos Vector2 screen position of bottom left of rendered text
---@param char string to render on screen
---@param width number
---@param color Color|nil color of text, defaults to black
TextRenderer.put_char_with_width = function(pos, char, width, color)
    put_char_with_scale(pos, char, width / TextRenderer.GLYPH_WIDTH, color)
end

local StringScale = function (str, width)
    return width / (#str * TextRenderer.GLYPH_WIDTH)
end

---@param pos Vector2 screen position of bottom left of rendered text
---@param str string to render on screen
---@param width number
---@param color Color|nil color of text, defaults to black
TextRenderer.put_string_with_width = function(pos, str, width, color)
    local scale = StringScale(str, width)
    for i=1, #str do
        local x = pos.x + (i-1) * scale * TextRenderer.GLYPH_WIDTH
        put_char_with_scale(Vector2(x, pos.y), str:sub(i,i), scale, color)
    end
    return scale * TextRenderer.GLYPH_HEIGHT
end

---@param str string to render on screen
---@param width number expected width of whole string
---@return table particles array with each particle's `offset` and `radius`
TextRenderer.build_particles_with_width = function (str, width)
    local particles = {}
    local scale = StringScale(str, width)
    for i=1, #str do
        local c = str:sub(i,i)
        local glyph = Glyph(c)
        local x = (i-1) * scale * TextRenderer.GLYPH_WIDTH
        for _,circle in ipairs(glyph) do
            table.insert(particles, {
                offset = Vector2(x, 0) + circle.pos * scale,
                radius = circle.radius * scale
            })
        end
    end
    -- metadata
    particles.height = scale * TextRenderer.GLYPH_HEIGHT
    return particles
end

TextRenderer.load_glyphs()

return TextRenderer
