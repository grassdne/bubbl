local ffi = require "ffi"
local bg = CreateCanvas { { Color.Hex("#202020") } }

return {
    title = "3D Bubble Testing",
    Draw = function (dt)
        ffi.C.render_box(Vector3(400, 300), Color.Hex("#00aaff", 1.0), 100);
    end,
}
