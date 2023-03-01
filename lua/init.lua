-- This is where all the C bindings and API functions are located

local ffi = require "ffi"
local C = ffi.C
ffi.cdef[[
typedef struct {
    float x, y;
} Vector2;

typedef struct {
    float r, g, b, a;
} Color;

typedef char GLbyte;

typedef struct  {
    Vector2 pos;
    float rad;
    Color color;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} Bubble;

typedef struct {
    uint8_t r, g, b, a;
} Pixel;

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
    float age;
} Particle;

// Opaque types
typedef struct {} BgShader;

typedef struct { unsigned int program; unsigned int vao; } Shader;

typedef struct Window Window;

typedef enum {
    EVENT_NONE=0,
    EVENT_KEY, EVENT_MOUSEBUTTON,
    EVENT_MOUSEMOTION, EVENT_MOUSEWHEEL,
    EVENT_RESIZE,
} EventType;

typedef struct {
    EventType type;
    union {
        struct {
            const char *name;
            bool is_down;
        } key;
        struct {
            Vector2 position;
            bool is_down;
        } mousebutton;
        struct {
            Vector2 position;
        } mousemotion;
        struct {
            Vector2 scroll;
        } mousewheel;
        struct {
            int width, height;
        } resize;
    };
} Event;

BgShader* get_bg_shader(void);

enum{ MAX_ELEMS=10 };

void free(void *p);
void render_bubble(Bubble bubble);
void flush_bubbles(void);
void flush_pops(void);
void render_pop(Particle particle);
void bgshader_draw(BgShader *sh, Bubble *bubbles[MAX_ELEMS], size_t num_elems);
double get_time(void);
bool screenshot(const char *file_name);
void flush_renderers(void);
void clear_screen(void);
void bg_draw(void *data, int width, int height);

bool should_quit(void);
Window *create_window(const char *window_name, int width, int height);
void destroy_window(Window *window);
void set_window_title(Window *window, const char *title);
void SDL_GL_SwapWindow(Window *window);

Event poll_event(Window *window);
void update_screen(Window *window);
Vector2 get_mouse_position(Window *window);

void create_shader_program(Shader *shader, const char *id, const char *vertex_source, const char *fragment_source);
void run_shader_program(Shader *shader);
void use_shader_program(Shader *shader);
int glGetUniformLocation(unsigned int program, const char *name);
void glUniform4f(int uni, float r, float g, float b, float a);
void glUniform2f(int uni, float x, float y);
void glUniform1f(int uni, float f);
void glUniform4fv(int uni, int count, Color *values);
void glUniform2fv(int uni, int count, Vector2 *values);
]]

ParticleEntity = ffi.typeof("Particle")

local vec2_mt = {
    __add      = function (a, b)  return Vector2(a.x + b.x, a.y + b.y) end,
    __sub      = function (a, b)  return Vector2(a.x - b.x, a.y - b.y) end,
    __mul      = function (a, b)  return Vector2(a.x * b, a.y * b) end,
    __div      = function (a, b)  return Vector2(a.x / b, a.y / b) end,
    __unm      = function (v)     return Vector2(-v.x, -v.y) end,
    __tostring = function (v)
        return ("Vector2(%.2f, %.2f)"):format(v.x, v.y)
    end,

    dot        = function (a, b)    return a.x * b.x + a.y * b.y end,
    scale      = function (v, mult) return Vector2(v.x * mult, v.y * mult) end,
    lengthsq   = function (v)       return v.x*v.x + v.y*v.y end,
    length     = function (v)       return math.sqrt(v:lengthsq()) end,
    distsq     = function (a, b)    return (a - b):lengthsq() end,
    dist       = function (a, b)    return math.sqrt(a:distsq(b)) end,
    normalize  = function (v)       return v / v:length() end,
    delta_x    = function (v, dx) v.x = v.x + dx end,
    delta_y    = function (v, dy) v.y = v.y + dy end,
    unpack     = function(v) return tonumber(v.x), tonumber(v.y) end,
}
vec2_mt.__index = vec2_mt

--- Simple 2d vector
--- You shouldn't need to know that this is an ffi struct
--- rather than a Lua table. It's mostly just to make returning and passing
--- vectors from C simpler.
---@class Vector2
Vector2 = ffi.metatype("Vector2", vec2_mt)

local color_mt = {
    __tostring = function(c)
        return ("Color(%.2f, %.2f, %.2f)"):format(c.r, c.g, c.b)
    end,
    hex = function(hex, a)
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
    __add = function(a, b) return Color(a.r+b.r, a.g+b.g, a.b+b.b) end,
    __div = function(a, x) return Color(a.r/x, a.g/x, a.b/x) end,

    -- Translated from
    -- https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_RGB_alternative
    ---@param hue        number in range [0, 360]
    ---@param saturation number in range [0, 1]
    ---@param lightness  number in range [0, 1]
    ---@param alpha      number|nil (default 1)
    hsl = function(hue, saturation, lightness, alpha)
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
    to_hex_string = function(c)
        return "#"..string.format("%.2x", c.r*255)
                  ..string.format("%.2x", c.g*255)
                  ..string.format("%.2x", c.b*255)
    end,
    Pixel = function(c)
        return ffi.new("Pixel", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255), math.floor(c.a*255))
    end,
    unpack = function(c) return c.r, c.g, c.b, c.a end,
    mix = function(a, b, f)
        return Color(a.r * (1 - f) + b.r * f,
                     a.g * (1 - f) + b.g * f,
                     a.b * (1 - f) + b.b * f,
                     a.a * (1 - f) + a.a * f)
    end,
}
color_mt.__index = color_mt

--- RGBA color stored as floats [0-1]
--- Generally don't call constructor directly,
--- but use Color.hex or Color.hsl.
--- With most methods you can choose to neglect the alpha component.
---@class Color
Color = ffi.metatype("Color", color_mt)

local mt = {
}
mt.__index = mt
BubbleEntity = ffi.metatype("Bubble", mt)

Bubble = {}
Bubble.__index = Bubble
function Bubble:New(color, pos, velocity, radius)
    local bubble = setmetatable({}, self)
    bubble.position = pos
    bubble.color = color
    bubble.velocity = velocity
    bubble.radius = radius
    bubble.color_b = color
    bubble.trans_angle = Vector2(0,0)
    bubble.trans_percent = 0
    bubble.trans_starttime = nil
    return bubble
end
function Bubble:StartTransformation(color, start_time, angle)
    self.color_b = color
    self.trans_percent = 0
    self.trans_starttime = start_time
    self.trans_angle = angle
end
function Bubble:CBubble()
    return BubbleEntity {
        pos = self.position,
        rad = self.radius,
        color = self.color,
        color_b = self.color_b or self.color,
        trans_angle = self.trans_angle or Vector2(0,0),
        trans_percent = self.trans_percent or 0,
    }
end

RenderBubble = function (bubble)
    C.render_bubble(bubble:CBubble())
end

RenderSimple = function (pos, color, rad,
                          opt_color_b, opt_trans_angle, opt_trans_percent)
    local bubble = BubbleEntity()
    bubble.pos = pos
    bubble.rad = rad
    bubble.color = color
    bubble.color_b = opt_color_b or color
    -- If number, convert to vector
    bubble.trans_angle = type(opt_trans_angle) == "number"
                         and Vector2(math.cos(opt_trans_angle, math.sin(opt_trans_angle)))
                         or opt_trans_angle or Vector2(0,0)
    bubble.trans_percent = opt_trans_percent or 0
    C.render_bubble(bubble)
end

RenderPop = function (pos, color, radius, age)
    C.render_pop(ParticleEntity(pos, color, radius, age))
end

local mt = {
    New = function (Self)
        return C.get_bg_shader()
    end;
    draw = function (shader, bubbles)
        assert(#bubbles == 0 or ffi.istype(BubbleEntity, bubbles[1]), "expected bubble entity")
        C.bgshader_draw(shader, ffi.new("Bubble*[10]", bubbles), #bubbles)
    end;
}
mt.__index = mt
BgShader = ffi.metatype("BgShader", mt)

math.randomseed(os.time())

dbg = function(...) print(...) return ... end

local locked_mt = {
    __newindex = function(t, k, v)
        error("attempt to set undeclared global \""..k.."\"", 2)
    end;
    __index = function(t, k)
        error("attempt to get undeclared global \""..k.."\"", 2)
    end;
}
LockTable = function(t)
    setmetatable(t, locked_mt)
end

package.path = "./lua/?.lua;" .. package.path

--https://developer.mozilla.org/en-US/docs/Web/CSS/named-color
WEBCOLORS = {
    BLACK = Color.hex "#000000",
    SILVER = Color.hex "#c0c0c0",
    GRAY = Color.hex "#808080",
    WHITE = Color.hex "#ffffff",
    MAROON = Color.hex "#800000",
    RED = Color.hex "#ff0000",
    PURPLE = Color.hex "#800080",
    FUCHSIA = Color.hex "#ff00ff",
    GREEN = Color.hex "#008000",
    LIME = Color.hex "#00ff00",
    OLIVE = Color.hex "#808000",
    YELLOW = Color.hex "#ffff00",
    NAVY = Color.hex "#000080",
    BLUE = Color.hex "#0000ff",
    TEAL = Color.hex "#008080",
    AQUA = Color.hex "#00ffff",
    ORANGE = Color.hex "#ffa500",
    ALICEBLUE = Color.hex "#f0f8ff",
    ANTIQUEWHITE = Color.hex "#faebd7",
    AQUAMARINE = Color.hex "#7fffd4",
    AZURE = Color.hex "#f0ffff",
    BEIGE = Color.hex "#f5f5dc",
    BISQUE = Color.hex "#ffe4c4",
    BLANCHEDALMOND = Color.hex "#ffebcd",
    BLUEVIOLET = Color.hex "#8a2be2",
    BROWN = Color.hex "#a52a2a",
    BURLYWOOD = Color.hex "#deb887",
    CADETBLUE = Color.hex "#5f9ea0",
    CHARTREUSE = Color.hex "#7fff00",
    CHOCOLATE = Color.hex "#d2691e",
    CORAL = Color.hex "#ff7f50",
    CORNFLOWERBLUE = Color.hex "#6495ed",
    CORNSILK = Color.hex "#fff8dc",
    CRIMSON = Color.hex "#dc143c",
    DARKBLUE = Color.hex "#00008b",
    DARKCYAN = Color.hex "#008b8b",
    DARKGOLDENROD = Color.hex "#b8860b",
    DARKGRAY = Color.hex "#a9a9a9",
    DARKGREEN = Color.hex "#006400",
    DARKGREY = Color.hex "#a9a9a9",
    DARKKHAKI = Color.hex "#bdb76b",
    DARKMAGENTA = Color.hex "#8b008b",
    DARKOLIVEGREEN = Color.hex "#556b2f",
    DARKORANGE = Color.hex "#ff8c00",
    DARKORCHID = Color.hex "#9932cc",
    DARKRED = Color.hex "#8b0000",
    DARKSALMON = Color.hex "#e9967a",
    DARKSEAGREEN = Color.hex "#8fbc8f",
    DARKSLATEBLUE = Color.hex "#483d8b",
    DARKSLATEGRAY = Color.hex "#2f4f4f",
    DARKSLATEGREY = Color.hex "#2f4f4f",
    DARKTURQUOISE = Color.hex "#00ced1",
    DARKVIOLET = Color.hex "#9400d3",
    DEEPPINK = Color.hex "#ff1493",
    DEEPSKYBLUE = Color.hex "#00bfff",
    DIMGRAY = Color.hex "#696969",
    DIMGREY = Color.hex "#696969",
    DODGERBLUE = Color.hex "#1e90ff",
    FIREBRICK = Color.hex "#b22222",
    FLORALWHITE = Color.hex "#fffaf0",
    FORESTGREEN = Color.hex "#228b22",
    GAINSBORO = Color.hex "#dcdcdc",
    GHOSTWHITE = Color.hex "#f8f8ff",
    GOLD = Color.hex "#ffd700",
    GOLDENROD = Color.hex "#daa520",
    GREENYELLOW = Color.hex "#adff2f",
    GREY = Color.hex "#808080",
    HONEYDEW = Color.hex "#f0fff0",
    HOTPINK = Color.hex "#ff69b4",
    INDIANRED = Color.hex "#cd5c5c",
    INDIGO = Color.hex "#4b0082",
    IVORY = Color.hex "#fffff0",
    KHAKI = Color.hex "#f0e68c",
    LAVENDER = Color.hex "#e6e6fa",
    LAVENDERBLUSH = Color.hex "#fff0f5",
    LAWNGREEN = Color.hex "#7cfc00",
    LEMONCHIFFON = Color.hex "#fffacd",
    LIGHTBLUE = Color.hex "#add8e6",
    LIGHTCORAL = Color.hex "#f08080",
    LIGHTCYAN = Color.hex "#e0ffff",
    LIGHTGOLDENRODYELLOW = Color.hex "#fafad2",
    LIGHTGRAY = Color.hex "#d3d3d3",
    LIGHTGREEN = Color.hex "#90ee90",
    LIGHTGREY = Color.hex "#d3d3d3",
    LIGHTPINK = Color.hex "#ffb6c1",
    LIGHTSALMON = Color.hex "#ffa07a",
    LIGHTSEAGREEN = Color.hex "#20b2aa",
    LIGHTSKYBLUE = Color.hex "#87cefa",
    LIGHTSLATEGRAY = Color.hex "#778899",
    LIGHTSLATEGREY = Color.hex "#778899",
    LIGHTSTEELBLUE = Color.hex "#b0c4de",
    LIGHTYELLOW = Color.hex "#ffffe0",
    LIMEGREEN = Color.hex "#32cd32",
    LINEN = Color.hex "#faf0e6",
    MEDIUMAQUAMARINE = Color.hex "#66cdaa",
    MEDIUMBLUE = Color.hex "#0000cd",
    MEDIUMORCHID = Color.hex "#ba55d3",
    MEDIUMPURPLE = Color.hex "#9370db",
    MEDIUMSEAGREEN = Color.hex "#3cb371",
    MEDIUMSLATEBLUE = Color.hex "#7b68ee",
    MEDIUMSPRINGGREEN = Color.hex "#00fa9a",
    MEDIUMTURQUOISE = Color.hex "#48d1cc",
    MEDIUMVIOLETRED = Color.hex "#c71585",
    MIDNIGHTBLUE = Color.hex "#191970",
    MINTCREAM = Color.hex "#f5fffa",
    MISTYROSE = Color.hex "#ffe4e1",
    MOCCASIN = Color.hex "#ffe4b5",
    NAVAJOWHITE = Color.hex "#ffdead",
    OLDLACE = Color.hex "#fdf5e6",
    OLIVEDRAB = Color.hex "#6b8e23",
    ORANGERED = Color.hex "#ff4500",
    ORCHID = Color.hex "#da70d6",
    PALEGOLDENROD = Color.hex "#eee8aa",
    PALEGREEN = Color.hex "#98fb98",
    PALETURQUOISE = Color.hex "#afeeee",
    PALEVIOLETRED = Color.hex "#db7093",
    PAPAYAWHIP = Color.hex "#ffefd5",
    PEACHPUFF = Color.hex "#ffdab9",
    PERU = Color.hex "#cd853f",
    PINK = Color.hex "#ffc0cb",
    PLUM = Color.hex "#dda0dd",
    POWDERBLUE = Color.hex "#b0e0e6",
    ROSYBROWN = Color.hex "#bc8f8f",
    ROYALBLUE = Color.hex "#4169e1",
    SADDLEBROWN = Color.hex "#8b4513",
    SALMON = Color.hex "#fa8072",
    SANDYBROWN = Color.hex "#f4a460",
    SEAGREEN = Color.hex "#2e8b57",
    SEASHELL = Color.hex "#fff5ee",
    SIENNA = Color.hex "#a0522d",
    SKYBLUE = Color.hex "#87ceeb",
    SLATEBLUE = Color.hex "#6a5acd",
    SLATEGRAY = Color.hex "#708090",
    SLATEGREY = Color.hex "#708090",
    SNOW = Color.hex "#fffafa",
    SPRINGGREEN = Color.hex "#00ff7f",
    STEELBLUE = Color.hex "#4682b4",
    TAN = Color.hex "#d2b48c",
    THISTLE = Color.hex "#d8bfd8",
    TOMATO = Color.hex "#ff6347",
    TURQUOISE = Color.hex "#40e0d0",
    VIOLET = Color.hex "#ee82ee",
    WHEAT = Color.hex "#f5deb3",
    WHITESMOKE = Color.hex "#f5f5f5",
    YELLOWGREEN = Color.hex "#9acd32",
}

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

MousePosition = function ()
    return C.get_mouse_position(window)
end

ArrayFind = function (array, item)
    for i,v in ipairs(array) do
        if v == item then return i end
    end
end

Seconds = function() return C.get_time() end

Title = function(name)
    assert(type(name) == "string", "expected string `name` for Title")
    C.set_window_title(window, name)
end

Screenshot = function(name)
    assert(type(name) == "string", "expected string file name for Screenshot")
    return C.screenshot(name);
end

FlushRenderers = function()
    C.flush_renderers()
end
ClearScreen = function()
    C.clear_screen()
end

DrawCanvas = function(canvas)
    C.bg_draw(canvas.data, canvas.width, canvas.height)
end

UpdateScreen = function (window)
    C.update_screen(window);
end

CreateWindow = function(name, width, height)
    assert(type(name) == "string", "expected string `name`")
    assert(type(width) == "number", "expected number `width`")
    assert(type(height) == "number", "expected height `height`")
    return ffi.gc(C.create_window(name, width, height), C.destroy_window)
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

local canvas_mt = {
    set = function(canvas, x, y, color)
        assert(y < canvas.height, "canvas:set y argument out of range")
        assert(x < canvas.width, "canvas:set x argument out of range")
        canvas.data[y * canvas.width + x] = color:Pixel()
    end,
    new = function(self, ...)
        if type(...) == "table" then
            return CanvasFromTable(...)
        else
            return CreateCanvas(...)
        end
    end,
    draw = function(canvas)
        C.bg_draw(canvas.data, canvas.width, canvas.height)
    end

}
canvas_mt.__index = canvas_mt
Canvas = ffi.metatype("struct { int width; int height; Pixel data[?]; }", canvas_mt)

---@param width number
---@param height number
CreateCanvas = function(width, height)
    assert(type(width) == "number")
    assert(type(height) == "number")
    return Canvas(width*height, width, height)
end

-- Pending event iterator for event loop
local NextEvent = function()
    local event = C.poll_event(window)
    if event.type ~= "EVENT_NONE" then
        return event
    end
end
function PendingEvents() return NextEvent end

local shaders = {}
ClearShaderCache = function()
    -- TODO: free shit?
    shaders = {}
end

--- This should probably be put in some namespace, if at all global
---@param file_name string
ReadEntireFile = function (file_name)
    local file = assert(io.open(file_name))
    local result = file:read("*a")
    file:close()
    return result
end

local bg_vertex_shader_source = ReadEntireFile("shaders/bg.vert")

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
            C.glUniform4f(uniforms[name], arg:unpack())

        elseif ffi.istype(Vector2, arg) then
            C.glUniform2f(uniforms[name], arg:unpack())

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

require "scheduler"

window_width = 1600
window_height = 900
window = CreateWindow("Bubble", window_width, window_height)
