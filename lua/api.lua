-- This is where all the C bindings and API functions are located

local ffi = require "ffi"

local C = ffi.C
-- Gifski is optional; it's only needed for generating gifs
local gifski
local RequireGifski = function()
    if not gifski then gifski = ffi.load("deps/gifski/target/release/libgifski.so") end
end

----------------------------
--------- Lua Utility ------
----------------------------

-- utilities around math.random()
random = {
    sign = function()
        return math.random() > 0.5 and 1 or -1
    end;
    vary = function (base, vary)
        return base + vary * math.random()
    end;
    minmax = function (min, max)
        return math.random() * (max - min) + min
    end;
    select = function (a)
        return a[math.random(1, #a)]
    end;
    shuffle = function (a)
        for i = 1, #a-1 do
            local i2 = math.random(i+1, #a)
            a[i], a[i2] = a[i2], a[i]
        end
        return a
    end;
}
PI = math.pi

table.copy = function(tbl)
    local cpy = {}
    for k,v in pairs(tbl) do cpy[k] = v end
    return cpy
end

math.clamp = function(v, min, max)
    return math.max(min, math.min(max, v))
end

math.sign = function(v) return v < 0 and -1 or v > 0 and 1 or 0 end

MousePosition = function ()
    return C.get_mouse_position(window)
end

ArrayFind = function (array, item)
    for i,v in ipairs(array) do
        if v == item then return i end
    end
end

dbg = function(...) print(...) return ... end

-- The most barebones of class implementations
Parent = function (t)
    t.__index = t
    return t
end

local Dumper
Dumper = function (x, indent)
    if type(x) == "table" then
        print()
        for k,v in pairs(x) do
            io.write(indent, tostring(k), ": ")
            Dumper(v, indent..'\t')
        end
    else
        print(x)
    end
end
--TODO: fully implement
Dump = function (v)
    Dumper(v, '\t')
end

Deepcopy = function (t)
    if type(t) ~= "table" then return t end
    local new = {}
    for k,v in pairs(t) do
        new[k] = Deepcopy(v)
    end
    return new
end

Lerp = function (a, b, t) return (b - a) * t + a end

----------------------------
--------- Vector2 ----------
----------------------------

--- Simple 2d vector
--- You shouldn't need to know that this is an ffi struct
--- rather than a Lua table. It's mostly just to make returning and passing
--- vectors from C simpler.
---@class Vector2
Vector2 = ffi.metatype("Vector2", Parent {
    __add = function (a, b) return Vector2(a.x + b.x, a.y + b.y) end,
    __sub = function (a, b) return Vector2(a.x - b.x, a.y - b.y) end,
    __mul = function (a, b) return Vector2(a.x * b, a.y * b) end,
    __div = function (a, b) return Vector2(a.x / b, a.y / b) end,
    __unm = function (v) return Vector2(-v.x, -v.y) end,

    __tostring = function (v)
        return string.format("Vector2(%.2f, %.2f)", v.x, v.y)
    end,

    Dot = function (a, b) return a.x * b.x + a.y * b.y end,
    Scale = function (a, b) return Vector2(a.x * b.x, a.y * b.y) end,
    LengthSq = function (v) return v.x*v.x + v.y*v.y end,
    Length = function (v) return math.sqrt(v:LengthSq()) end,
    DistSq = function (a, b) return (a - b):LengthSq() end,
    Dist = function (a, b) return math.sqrt(a:DistSq(b)) end,
    Normalize = function (v) return v / v:Length() end,
    DeltaX = function (v, dx) v.x = v.x + dx end,
    DeltaY = function (v, dy) v.y = v.y + dy end,
    Unpack = function(v) return tonumber(v.x), tonumber(v.y) end,
    Angle = function (theta) return Vector2(math.cos(theta), math.sin(theta)) end,
    Lerp = Lerp,
})

----------------------------
--------- Color ----------
----------------------------

--- RGBA color stored as floats [0-1]
--- Generally don't call constructor directly,
--- but use Color.Hex or Color.Hsl.
--- With most methods you can choose to neglect the alpha component.
---@class Color
Color = ffi.metatype("Color", Parent {
    __tostring = function(c)
        return ("Color(%.2f, %.2f, %.2f, %.2f)"):format(c.r, c.g, c.b, c.a)
    end,
    Hex = function(hex, a)
        if hex:sub(1, 1) == '#' then hex = hex:sub(2) end
        assert(#hex == 6 and "hex string should be an optional '#' plus six hexadecimal digits")
        local r = tonumber(hex:sub(1, 2), 16) / 0xFF
        local g = tonumber(hex:sub(3, 4), 16) / 0xFF
        local b = tonumber(hex:sub(5, 6), 16) / 0xFF
        return Color(r, g, b, a or 1)
    end,
    random = function()
        return Color(math.random(), math.random(), math.random())
    end,
    __add = function(a, b) return Color(a.r+b.r, a.g+b.g, a.b+b.b, a.a+b.a) end,
    __sub = function(a, b) return Color(a.r-b.r, a.g-b.g, a.b-b.b, a.a-b.a) end,
    __mul = function(a, x) return Color(a.r*x, a.g*x, a.b*x, a.a*x) end,
    __div = function(a, x) return Color(a.r/x, a.g/x, a.b/x, a.a/x) end,

    -- Translated from
    -- https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_RGB_alternative
    ---@param hue        number in range [0, 360]
    ---@param saturation number in range [0, 1]
    ---@param lightness  number in range [0, 1]
    ---@param alpha      number|nil (default 1)
    Hsl = function(hue, saturation, lightness, alpha)
            local a = saturation * math.min(lightness, 1 - lightness)

            local k = (0 + hue / 30) % 12
            local red = lightness - a * math.max(-1, math.min(k - 3, 9 - k, 1))

            local k = (8 + hue / 30) % 12
            local green = lightness - a * math.max(-1, math.min(k - 3, 9 - k, 1))

            local k = (4 + hue / 30) % 12
            local blue = lightness - a * math.max(-1, math.min(k - 3, 9 - k, 1))

            -- TODO: alpha
            return Color(red, green, blue, alpha or 1)
    end,
    ToHexString = function(c)
        return "#"..string.format("%.2x", c.r*255)
                  ..string.format("%.2x", c.g*255)
                  ..string.format("%.2x", c.b*255)
    end,
    Pixel = function(c)
        return ffi.new("Pixel", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255), math.floor(c.a*255))
    end,
    Unpack = function(c) return c.r, c.g, c.b, c.a end,
    Lerp = Lerp,
})

----------------------------
--------- Entities ----------
----------------------------

local BubbleEntity = ffi.typeof("Bubble")

RenderBubble = function (pos, color, rad)
    C.render_bubble(BubbleEntity(pos, rad, color, color))
end

local ParticleEntity = ffi.typeof("Particle")

RenderPop = function (pos, color, radius)
    C.render_pop(ParticleEntity(pos, color, radius))
end


----------------------------
------- Interface ----------
----------------------------

Seconds = function() return C.get_time() end

Title = function(name)
    assert(type(name) == "string", "expected string `name` for Title")
    C.set_window_title(window, name)
end

Size = function (width, height)
    resolution.x = width
    resolution.y = height
    C.set_window_size(window, width, height);
end

FlushRenderers = function()
    C.flush_renderers()
end

StartDrawing = function()
    C.start_drawing(window)
end

UpdateScreen = function (window)
    C.update_screen(window);
end

local quit = false
Quit = function()
    quit = true
end
function ShouldQuit()
    return quit or C.should_quit()
end

-- For scheduler ONLY
-- Pending event iterator for event loop
local NextEvent = function()
    local event = C.poll_event(window)
    if event.type ~= "EVENT_NONE" then
        return event
    end
end
function PendingEvents() return NextEvent end

-- TODO: support multiple windows
CreateWindow = function(name, width, height)
    assert(type(name) == "string", "expected string `name`")
    assert(type(width) == "number", "expected number `width`")
    assert(type(height) == "number", "expected height `height`")
    return ffi.gc(C.create_window(name, width, height), C.destroy_window)
end

Warning = function (...)
    io.stderr:write("WARNING: ", ...)
    io.stderr:write("\n")
end

Info = function (...)
    io.stderr:write("INFO: ", ...)
    io.stderr:write("\n")
end

----------------------------
------ Background ----------
----------------------------

local canvas_mt = {
    set = function(canvas, x, y, color)
        assert(y < canvas.height, "canvas:set y argument out of range")
        assert(x < canvas.width, "canvas:set x argument out of range")
        canvas.data[y * canvas.width + x] = color:Pixel()
    end,
    draw = function(canvas)
        if canvas.texture == 0 then
            canvas.texture = C.bg_create_texture(canvas.data, canvas.width, canvas.height)
        end
        C.bg_draw(canvas.texture, canvas.data, canvas.width, canvas.height)
    end
}
canvas_mt.__index = canvas_mt

---@param width number
---@param height number
local GenCanvas = function(width, height)
    assert(type(width) == "number")
    assert(type(height) == "number")
    local canvas = setmetatable({
        width = width,
        height = height,
        data = ffi.new("Pixel[?]", width*height),
        texture = 0
    }, canvas_mt)
    return canvas
end

local CanvasFromTable = function(field)
    local height = #field
    assert(height > 0, "canvas must have height > 0")
    local width = #field[1]
    local canvas = CreateCanvas(width, height)
    for y = 1, height do
        for x = 1, width do
            canvas:set(x-1, y-1, field[y][x])
        end
    end
    return canvas
end

CreateCanvas = function(...)
    if type(...) == "table" then
        return CanvasFromTable(...)
    else
        return GenCanvas(...)
    end
end


local bg_vertex_shader_source = ReadEntireFile("shaders/bg.vert")
local shaders = {}
ClearShaderCache = function()
    -- TODO: free shit?
    shaders = {}
end
--- Run a simple fragment shader over the entire screen.
--- No need to declare or initialize anything,
--- the program is automatically created and cached.
---
--- NOTE: Passing in a string for the fragment shader is taken
--- as the **file path** for the location of the shader source,
--- not the source itself. Instead pass in a function that generates
--- and returns the string.
--- 
---@param id string used to cache program/uniforms and error messages
---@param frag_shader string|function either file path or function that returns string
---@param data table<string, number|Vector2|Color|table> uniform variables
RunBgShader = function(id, frag_shader, data)
    if not shaders[id] then
        local program = ffi.new("Shader")
        local frag_source
        if type(frag_shader) == "string" then
            frag_source = ReadEntireFile(frag_shader)
        elseif type(frag_shader) == "function" then
            frag_source = frag_shader()
            assert(type(frag_source) == "string", "RunBgShader shader loader callback must return string")
        else
            error("expected string file name or function for frag_shader", 2)
        end
        assert(type(id) == "string")
        C.create_shader_program(program, id, bg_vertex_shader_source, frag_source)
        shaders[id] = { program, {} }
    end
    local program, uniforms = unpack(shaders[id])
    C.use_shader_program(program)
    for name, arg in pairs(data) do
        if not uniforms[name] then
            uniforms[name] = C.glGetUniformLocation(program.program, name)
        end
        if ffi.istype(Color, arg) then
            C.glUniform4f(uniforms[name], arg:Unpack())

        elseif ffi.istype(Vector2, arg) then
            C.glUniform2f(uniforms[name], arg:Unpack())

        elseif type(arg) == "number" then
            C.glUniform1f(uniforms[name], arg)

        elseif type(arg) == "table" then
            assert(arg[1], "array uniform must contain at least one value")
            if ffi.istype(Color, arg[1]) then
                C.glUniform4fv(uniforms[name], #arg, ffi.new("Color[?]", #arg, arg))
            elseif ffi.istype(Vector2, arg[1]) then
                C.glUniform2fv(uniforms[name], #arg, ffi.new("Vector2[?]", #arg, arg))
            else
                assert(false, "unknown uniform type")
            end

        else
            assert(false, "unknown uniform type")
        end
    end
    C.run_shader_program(program)
end

----------------------------
------- Recording ----------
----------------------------

Screenshot = function(name)
    assert(type(name) == "string", "expected string file name for Screenshot")
    return C.screenshot(window, name);
end

local gifskis = {}
GifNew = function (file_name, settings)
    RequireGifski()
    assert(type(file_name) == "string", "expected string file name for GifNew")
    local p = ffi.new("GifskiSettings[1]", { settings or {quality=90 } })
    local gif = gifski.gifski_new(p);
    if gif == nil then
        print("ERROR: invalid settings for GIF")
        return
    end
    gifski.gifski_set_file_output(gif, file_name)
    gifskis[file_name] = gif
end

GifAddFrame = function (file_name, frame_number, timestamp)
    RequireGifski()
    assert(type(file_name) == "string", "expected string file name")
    assert(type(frame_number) == "number", "expected gif frame number")
    if not gifskis[file_name] then GifNew(file_name) end
    local pixels = ffi.new("uint8_t[?]", 4 * resolution.x * resolution.y)
    C.get_screen_pixels(window, pixels)
    if pixels == nil then
        print("ERROR: Unable to read screen content")
        return
    end
    print(resolution.x, resolution.y)
    local err = gifski.gifski_add_frame_rgba(gifskis[file_name], frame_number, resolution.x, resolution.y, pixels, timestamp)
    if err ~= "GIFSKI_OK" then print("ERROR: (Code "..err..") Unable to add GIF frame to "..file_name) end
    print(file_name.." adding frame "..frame_number)
end

GifFinish = function (file_name)
    RequireGifski()
    -- If no file name provided, complete all GIFs
    if not file_name then
        for k in pairs(gifskis) do
            GifFinish(k)
        end
        return
    end
    assert(type(file_name) == "string" and gifskis[file_name],
           "invalid file name passed to GifFinish")
    print(gifskis[file_name])
    local err = gifski.gifski_finish(gifskis[file_name])
    if err ~= "GIFSKI_OK" then
        print("ERROR: Unable to create GIF "..file_name)
        print("Error code: "..tostring(err))
    end
    print(file_name.." is completed!!")
end


----------------------------
---------- Colors ----------
----------------------------
--https://developer.mozilla.org/en-US/docs/Web/CSS/named-color
WEBCOLORS = {
    BLACK = Color.Hex "#000000",
    SILVER = Color.Hex "#c0c0c0",
    GRAY = Color.Hex "#808080",
    WHITE = Color.Hex "#ffffff",
    MAROON = Color.Hex "#800000",
    RED = Color.Hex "#ff0000",
    PURPLE = Color.Hex "#800080",
    FUCHSIA = Color.Hex "#ff00ff",
    GREEN = Color.Hex "#008000",
    LIME = Color.Hex "#00ff00",
    OLIVE = Color.Hex "#808000",
    YELLOW = Color.Hex "#ffff00",
    NAVY = Color.Hex "#000080",
    BLUE = Color.Hex "#0000ff",
    TEAL = Color.Hex "#008080",
    AQUA = Color.Hex "#00ffff",
    ORANGE = Color.Hex "#ffa500",
    ALICEBLUE = Color.Hex "#f0f8ff",
    ANTIQUEWHITE = Color.Hex "#faebd7",
    AQUAMARINE = Color.Hex "#7fffd4",
    AZURE = Color.Hex "#f0ffff",
    BEIGE = Color.Hex "#f5f5dc",
    BISQUE = Color.Hex "#ffe4c4",
    BLANCHEDALMOND = Color.Hex "#ffebcd",
    BLUEVIOLET = Color.Hex "#8a2be2",
    BROWN = Color.Hex "#a52a2a",
    BURLYWOOD = Color.Hex "#deb887",
    CADETBLUE = Color.Hex "#5f9ea0",
    CHARTREUSE = Color.Hex "#7fff00",
    CHOCOLATE = Color.Hex "#d2691e",
    CORAL = Color.Hex "#ff7f50",
    CORNFLOWERBLUE = Color.Hex "#6495ed",
    CORNSILK = Color.Hex "#fff8dc",
    CRIMSON = Color.Hex "#dc143c",
    DARKBLUE = Color.Hex "#00008b",
    DARKCYAN = Color.Hex "#008b8b",
    DARKGOLDENROD = Color.Hex "#b8860b",
    DARKGRAY = Color.Hex "#a9a9a9",
    DARKGREEN = Color.Hex "#006400",
    DARKGREY = Color.Hex "#a9a9a9",
    DARKKHAKI = Color.Hex "#bdb76b",
    DARKMAGENTA = Color.Hex "#8b008b",
    DARKOLIVEGREEN = Color.Hex "#556b2f",
    DARKORANGE = Color.Hex "#ff8c00",
    DARKORCHID = Color.Hex "#9932cc",
    DARKRED = Color.Hex "#8b0000",
    DARKSALMON = Color.Hex "#e9967a",
    DARKSEAGREEN = Color.Hex "#8fbc8f",
    DARKSLATEBLUE = Color.Hex "#483d8b",
    DARKSLATEGRAY = Color.Hex "#2f4f4f",
    DARKSLATEGREY = Color.Hex "#2f4f4f",
    DARKTURQUOISE = Color.Hex "#00ced1",
    DARKVIOLET = Color.Hex "#9400d3",
    DEEPPINK = Color.Hex "#ff1493",
    DEEPSKYBLUE = Color.Hex "#00bfff",
    DIMGRAY = Color.Hex "#696969",
    DIMGREY = Color.Hex "#696969",
    DODGERBLUE = Color.Hex "#1e90ff",
    FIREBRICK = Color.Hex "#b22222",
    FLORALWHITE = Color.Hex "#fffaf0",
    FORESTGREEN = Color.Hex "#228b22",
    GAINSBORO = Color.Hex "#dcdcdc",
    GHOSTWHITE = Color.Hex "#f8f8ff",
    GOLD = Color.Hex "#ffd700",
    GOLDENROD = Color.Hex "#daa520",
    GREENYELLOW = Color.Hex "#adff2f",
    GREY = Color.Hex "#808080",
    HONEYDEW = Color.Hex "#f0fff0",
    HOTPINK = Color.Hex "#ff69b4",
    INDIANRED = Color.Hex "#cd5c5c",
    INDIGO = Color.Hex "#4b0082",
    IVORY = Color.Hex "#fffff0",
    KHAKI = Color.Hex "#f0e68c",
    LAVENDER = Color.Hex "#e6e6fa",
    LAVENDERBLUSH = Color.Hex "#fff0f5",
    LAWNGREEN = Color.Hex "#7cfc00",
    LEMONCHIFFON = Color.Hex "#fffacd",
    LIGHTBLUE = Color.Hex "#add8e6",
    LIGHTCORAL = Color.Hex "#f08080",
    LIGHTCYAN = Color.Hex "#e0ffff",
    LIGHTGOLDENRODYELLOW = Color.Hex "#fafad2",
    LIGHTGRAY = Color.Hex "#d3d3d3",
    LIGHTGREEN = Color.Hex "#90ee90",
    LIGHTGREY = Color.Hex "#d3d3d3",
    LIGHTPINK = Color.Hex "#ffb6c1",
    LIGHTSALMON = Color.Hex "#ffa07a",
    LIGHTSEAGREEN = Color.Hex "#20b2aa",
    LIGHTSKYBLUE = Color.Hex "#87cefa",
    LIGHTSLATEGRAY = Color.Hex "#778899",
    LIGHTSLATEGREY = Color.Hex "#778899",
    LIGHTSTEELBLUE = Color.Hex "#b0c4de",
    LIGHTYELLOW = Color.Hex "#ffffe0",
    LIMEGREEN = Color.Hex "#32cd32",
    LINEN = Color.Hex "#faf0e6",
    MEDIUMAQUAMARINE = Color.Hex "#66cdaa",
    MEDIUMBLUE = Color.Hex "#0000cd",
    MEDIUMORCHID = Color.Hex "#ba55d3",
    MEDIUMPURPLE = Color.Hex "#9370db",
    MEDIUMSEAGREEN = Color.Hex "#3cb371",
    MEDIUMSLATEBLUE = Color.Hex "#7b68ee",
    MEDIUMSPRINGGREEN = Color.Hex "#00fa9a",
    MEDIUMTURQUOISE = Color.Hex "#48d1cc",
    MEDIUMVIOLETRED = Color.Hex "#c71585",
    MIDNIGHTBLUE = Color.Hex "#191970",
    MINTCREAM = Color.Hex "#f5fffa",
    MISTYROSE = Color.Hex "#ffe4e1",
    MOCCASIN = Color.Hex "#ffe4b5",
    NAVAJOWHITE = Color.Hex "#ffdead",
    OLDLACE = Color.Hex "#fdf5e6",
    OLIVEDRAB = Color.Hex "#6b8e23",
    ORANGERED = Color.Hex "#ff4500",
    ORCHID = Color.Hex "#da70d6",
    PALEGOLDENROD = Color.Hex "#eee8aa",
    PALEGREEN = Color.Hex "#98fb98",
    PALETURQUOISE = Color.Hex "#afeeee",
    PALEVIOLETRED = Color.Hex "#db7093",
    PAPAYAWHIP = Color.Hex "#ffefd5",
    PEACHPUFF = Color.Hex "#ffdab9",
    PERU = Color.Hex "#cd853f",
    PINK = Color.Hex "#ffc0cb",
    PLUM = Color.Hex "#dda0dd",
    POWDERBLUE = Color.Hex "#b0e0e6",
    ROSYBROWN = Color.Hex "#bc8f8f",
    ROYALBLUE = Color.Hex "#4169e1",
    SADDLEBROWN = Color.Hex "#8b4513",
    SALMON = Color.Hex "#fa8072",
    SANDYBROWN = Color.Hex "#f4a460",
    SEAGREEN = Color.Hex "#2e8b57",
    SEASHELL = Color.Hex "#fff5ee",
    SIENNA = Color.Hex "#a0522d",
    SKYBLUE = Color.Hex "#87ceeb",
    SLATEBLUE = Color.Hex "#6a5acd",
    SLATEGRAY = Color.Hex "#708090",
    SLATEGREY = Color.Hex "#708090",
    SNOW = Color.Hex "#fffafa",
    SPRINGGREEN = Color.Hex "#00ff7f",
    STEELBLUE = Color.Hex "#4682b4",
    TAN = Color.Hex "#d2b48c",
    THISTLE = Color.Hex "#d8bfd8",
    TOMATO = Color.Hex "#ff6347",
    TURQUOISE = Color.Hex "#40e0d0",
    VIOLET = Color.Hex "#ee82ee",
    WHEAT = Color.Hex "#f5deb3",
    WHITESMOKE = Color.Hex "#f5f5f5",
    YELLOWGREEN = Color.Hex "#9acd32",
}


----------------------------
-------- Config vars -------
----------------------------

Tweak = function (config)
    local t = {}
    for id, options in pairs(config) do
        t[id] = options.default or options.callback
        options["id"] = id
    end
    t._config = config
    return t
end
