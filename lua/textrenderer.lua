local glpyh_files = {
    ['A'] = 'A.svg',
    ['?'] = 'qmark.svg',
}
local glyphs = {}
glyphs[' '] = {}

local SIZE = 256

for char, file in pairs(glpyh_files) do
    local f = assert(io.open("glyphs/"..file))
    local contents = f:read("*a")
    local circles = {}
    for cx, cy, r, fill in
        contents:gmatch("<circle cx=\"(%d*)\" cy=\"(%d*)\" r=\"(%d*)\" fill=\"(%#%x*)\" />")
    do
        table.insert(circles, {
            pos = Vector2(tonumber(cx), SIZE - tonumber(cy)),
            radius = tonumber(r),
            color = Color.hex(fill),
        })
    end
    glyphs[char] = circles
    f:close()
end

put_char = function(popshader, pos, char, size)
    local circles = glyphs[char] or glyphs[' ']
    local scale = size / SIZE
    for _,circle in ipairs(circles) do
        popshader:render_particle(
            circle.pos:scale(scale) + pos,
            circle.color,
            circle.radius * scale,
            0
        )
    end
end

put_string = function(popshader, pos, str, fontsize)
    for i=1, #str do
        local x = pos.x + (i-1) * fontsize
        put_char(popshader, Vector2(x, pos.y), str:sub(i,i), fontsize)
    end
end
