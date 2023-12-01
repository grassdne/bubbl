-- Render text with a bunch of circles!

local TextRenderer = {}

-- TextRenderer.GLYPH_WIDTH = 135
TextRenderer.GLYPH_HEIGHT = 256

local fonts = {}

local NextSvgCircle = function (get_match)
    local cx, cy, r, fill = get_match()
    if cx then
        return Vector2(tonumber(cx), TextRenderer.GLYPH_HEIGHT - tonumber(cy)),
        tonumber(r),
        Color.Hex(fill)
    end
end
TextRenderer.SvgIterCircles = function (contents)
    local get_match = contents:gmatch("<circle cx=\"(%d*)\" cy=\"(%d*)\" r=\"(%d*)\" fill=\"(%#%x*)\" />")
    return NextSvgCircle, get_match
end

local current_font

TextRenderer.SvgGetSize = function (contents)
    local width, height = contents:match("<svg width=\"(%d+)\" height=\"(%d+)\">")
    return assert(tonumber(width)), assert(tonumber(height))
end

TextRenderer.LoadGlyphs = function(font_name)
    local glyph_files = {}
    local directory = "fonts/"..font_name.."/"
    local atlas = assert(io.open(directory.."atlas"))
    while atlas:read('l') == '' do
        -- TODO: unicode
        local glyph = string.char(atlas:read('l'))
        local file = atlas:read('l')
        glyph_files[glyph] = file
    end
    atlas:close()

    local glyphs = {}
    for char, file in pairs(glyph_files) do
        -- TODO: support having multiple fonts
        local f = assert(io.open(directory..file))
        local contents = f:read("*a")
        local circles = {}
        for pos, radius, color in TextRenderer.SvgIterCircles(contents) do
            table.insert(circles, {
                pos=pos,
                radius=radius,
            })
        end
        circles.width, circles.height = TextRenderer.SvgGetSize(contents)
        if not circles.width or not circles.height then print("WARNING: "..file.." missing svg dimensions") end
        glyphs[char] = circles
        f:close()
    end

    fonts[font_name] = glyphs
end

TextRenderer.SetFont = function (font)
    current_font = font
    if not fonts[current_font] then
        TextRenderer.LoadGlyphs(current_font)
    end
end

local Glyph = function (char) return fonts[current_font][char] or fonts[current_font][' '] end

local PutCharWithScale = function (pos, char, scale, color)
    color = color or WEBCOLORS.BLACK
    local circles = Glyph(char)
    for _,circle in ipairs(circles) do
        RenderPop(
            circle.pos * scale + pos,
            color,
            circle.radius * scale
        )
    end
    return circles.width * scale
end

---@param pos Vector2 screen position of bottom left of rendered text
---@param char string to render on screen
---@param width number
---@param color Color|nil color of text, defaults to black
TextRenderer.PutCharWithWidth = function(pos, char, width, color)
    PutCharWithScale(pos, char, width / Glyph(char).width, color)
end

local GetStringWidth = function (str)
    local w = 0
    for i=1, #str do
        w = w + Glyph(str:sub(i,i)).width
    end
    return w
end

local StringScale = function (str, width)
    return width / GetStringWidth(str)
end

---@param pos Vector2 screen position of bottom left of rendered text
---@param str string to render on screen
---@param width number
---@param color Color|nil color of text, defaults to black
TextRenderer.PutstringWithWidth = function(pos, str, width, color)
    local scale = StringScale(str, width)
    local x = pos.x
    for i=1, #str do
        x = x + PutCharWithScale(Vector2(x, pos.y), str:sub(i,i), scale, color)
    end
    return scale * TextRenderer.GLYPH_HEIGHT
end

-- TODO: return generator instead of table
---@param str string to render on screen
---@param width number expected width of whole string
---@return table particles array with each particle's `offset` and `radius`
TextRenderer.BuildParticlesWithWidth = function (str, width)
    local particles = {}
    local scale = StringScale(str, width)
    local x = 0
    for i=1, #str do
        local c = str:sub(i,i)
        local glyph = Glyph(c)
        for _,circle in ipairs(glyph) do
            table.insert(particles, {
                offset = Vector2(x, 0) + circle.pos * scale,
                radius = circle.radius * scale
            })
        end
        x = x + glyph.width * scale
    end
    -- metadata
    particles.height = scale * TextRenderer.GLYPH_HEIGHT
    return particles
end

TextRenderer.SetFont("Lora-VariableFont")
-- TextRenderer.SetFont("LiberationSans-Regular")
-- TextRenderer.SetFont("LiberationMono-Regular")
-- TextRenderer.SetFont("LiberationMono-cluster")
-- TextRenderer.SetFont("ugly")

return TextRenderer
