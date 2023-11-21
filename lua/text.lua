-- Render text with a bunch of circles!

local TextRenderer = {}

TextRenderer.GLYPH_WIDTH = 135
TextRenderer.GLYPH_HEIGHT = 256

local glyphs = {}

local FONT_DIR = "glyphs/Liberation Mono2/"

local glyph_files = {}
local atlas = io.open(FONT_DIR.."atlas")
while atlas:read('l') == '' do
    local glyph = atlas:read('l')
    local file = atlas:read('l')
    glyph_files[glyph] = file
end
atlas:close()
Dump(glyph_files)

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

TextRenderer.LoadGlyphs = function()
    for char, file in pairs(glyph_files) do
        -- TODO: support having multiple fonts
        local f = assert(io.open(FONT_DIR..file))
        local contents = f:read("*a")
        local circles = {}
        for pos, radius, color in TextRenderer.SvgIterCircles(contents) do
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

local Glyph = function (char) return glyphs[char] or glyphs[' '] end

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
end

---@param pos Vector2 screen position of bottom left of rendered text
---@param char string to render on screen
---@param width number
---@param color Color|nil color of text, defaults to black
TextRenderer.PutCharWithWidth = function(pos, char, width, color)
    PutCharWithScale(pos, char, width / TextRenderer.GLYPH_WIDTH, color)
end

local StringScale = function (str, width)
    return width / (#str * TextRenderer.GLYPH_WIDTH)
end

---@param pos Vector2 screen position of bottom left of rendered text
---@param str string to render on screen
---@param width number
---@param color Color|nil color of text, defaults to black
TextRenderer.PutstringWithWidth = function(pos, str, width, color)
    local scale = StringScale(str, width)
    for i=1, #str do
        local x = pos.x + (i-1) * scale * TextRenderer.GLYPH_WIDTH
        PutCharWithScale(Vector2(x, pos.y), str:sub(i,i), scale, color)
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

TextRenderer.LoadGlyphs()

return TextRenderer
