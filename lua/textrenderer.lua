SVG_SIZE = 256

local glpyh_files = {
    ['A'] = 'A.svg',
    ['?'] = 'qmark.svg',
}
local glyphs = {}
glyphs[' '] = {}

local TextRenderer = {}

local next_svg_circle = function (get_match)
    local cx, cy, r, fill = get_match()
    if cx then
        return Vector2(tonumber(cx), SVG_SIZE - tonumber(cy)),
        tonumber(r),
        Color.hex(fill)
    end
end
TextRenderer.svg_iter_circles = function (contents)
    local get_match = contents:gmatch("<circle cx=\"(%d*)\" cy=\"(%d*)\" r=\"(%d*)\" fill=\"(%#%x*)\" />")
    return next_svg_circle, get_match
end

TextRenderer.load_glyphs = function()
    for char, file in pairs(glpyh_files) do
        local f = assert(io.open("glyphs/"..file))
        local contents = f:read("*a")
        local circles = {}
        for pos, radius, color in TextRenderer.svg_iter_circles(contents) do
            table.insert(circles, {
                pos=pos,
                radius=radius,
                color=color,
            })
        end
        glyphs[char] = circles
        f:close()
    end
end

TextRenderer.put_char = function(pos, char, size)
    local circles = glyphs[char] or glyphs[' ']
    local scale = size / SVG_SIZE
    for _,circle in ipairs(circles) do
        render_pop(
            circle.pos:scale(scale) + pos,
            circle.color,
            circle.radius * scale,
            0
        )
    end
end

TextRenderer.put_string = function(pos, str, fontsize)
    for i=1, #str do
        local x = pos.x + (i-1) * fontsize
        TextRenderer.put_char(Vector2(x, pos.y), str:sub(i,i), fontsize)
    end
end

return TextRenderer
