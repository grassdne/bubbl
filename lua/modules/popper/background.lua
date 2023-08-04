local BGSHADER_MAX_ELEMS = 10

local BgShaderLoader = function()
    local contents = ReadEntireFile("shaders/elasticbubbles_bg.frag")
    return string.format("#version 330\n#define MAX_ELEMENTS %d\n%s", BGSHADER_MAX_ELEMS, contents)
end

return {
    Draw = function (bubbles)
        if #bubbles > 0 then
            table.sort(bubbles, function(a, b) return a:Radius() > b:Radius() end)
            local colors, positions = {}, {}
            for i=1, math.min(BGSHADER_MAX_ELEMS, #bubbles) do
                local bub = bubbles[i]
                colors[i] = bub:Color()
                positions[i] = bub.position
            end

            RunBgShader("elastic", BgShaderLoader, {
                resolution = resolution,
                num_elements = #bubbles,
                colors = colors,
                positions = positions,
            })
        end
    end;
}
