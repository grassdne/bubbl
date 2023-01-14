local ffi = require "ffi"
local C = ffi.C
ffi.cdef[[
typedef struct {
    float x, y;
} Vector2;

typedef struct {
    float r, g, b;
} Color;

typedef char GLbyte;

typedef struct  {
    Vector2 pos;
    Vector2 v;
    Color color;
    float rad;
    GLbyte alive;
    Vector2 trans_angle;
    Color trans_color;
    double trans_starttime;
    double last_transformation;
} Bubble;

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
    float age;
    bool alive;
} Particle;

// Opaque types
typedef struct {} BubbleShader;
typedef struct {} PoppingShader;
typedef struct {} BgShader;

BubbleShader* create_bubble_shader(void);
PoppingShader* create_pop_shader(void);
BgShader* create_bg_shader(BubbleShader *s);

enum{ MAX_ELEMS=10 };

int create_bubble(BubbleShader *s, Color color, Vector2 position, Vector2 velocity, int radius);
//void create_pop(PoppingShader *s, Vector2 pos, Color color, float rad);
void destroy_bubble(BubbleShader *s, size_t id);
int get_bubble_at_point(Vector2 pos);
Bubble *get_bubble(BubbleShader *s, size_t id);
void free(void *p);
void bubbleshader_draw(BubbleShader *s);
void pop_draw(PoppingShader *s, double dt);
Particle *pop_get_particle(PoppingShader *s, size_t id);
void pop_destroy_particle(PoppingShader *s, size_t id);
size_t push_particle(PoppingShader *s, Particle particle);
void bgshader_draw(BgShader *sh, const size_t indices[MAX_ELEMS], size_t num_elems);
double get_time(void);
typedef struct { int width; int height; } Dimensions;
Dimensions get_resolution(void);
]]

BGSHADER_MAX_ELEMS = 10

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
    unpack = function(v) return v.x, v.y end
}
vec2_mt.__index = vec2_mt
Vector2 = ffi.metatype("Vector2", vec2_mt)

local color_mt = {
    __tostring = function(c)
        return ("Color(%.2f, %.2f, %.2f)"):format(c.r, c.g, c.b)
    end,
    hex = function(hex)
        return Color(tonumber(assert(hex:sub(2, 3), "invalid hex string"), 16) / 0xFF,
        tonumber(assert(hex:sub(4, 4), "invalid hex string"), 16) / 0xFF,
        tonumber(assert(hex:sub(5, 6), "invalid hex string"), 16) / 0xFF)
    end,
    random = function()
        return Color(math.random(), math.random(), math.random())
    end,

    -- Translated directly from
    -- https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_RGB_alternative
    ---@param hue        number in range [0, 360]
    ---@param saturation number in range [0, 1]
    ---@param lightness  number in range [0, 1]
    hsl = function(hue, saturation, lightness)
        local function magic(n)
            local k = (n + hue / 30) % 12
            local a = saturation * math.min(lightness, 1 - lightness)
            return lightness - a * math.max(-1, math.min(k - 3, 9 - k, 1))
        end
        return Color(magic(0), magic(8), magic(4))
    end,
}
color_mt.__index = color_mt
Color = ffi.metatype("Color", color_mt)

local mt = {
    __gc = function(bubble)
        bubble.C.alive = false
    end,
}
mt.__index = mt
BubbleEntity = ffi.metatype("Bubble", mt)

Bubble = {}
Bubble.__index = Bubble
function Bubble:delta_radius(dr)
    self.C.rad = self.C.rad + dr
end
function Bubble:position(set)
    if set then self.C.pos = set end
    return Vector2(self.C.pos)
end
function Bubble:color(set)
    if set then self.C.color = set end
    return Color(self.C.color)
end
function Bubble:radius(set)
    if set then self.C.rad = set end
    return tonumber(self.C.rad)
end
function Bubble:velocity(set)
    if set then self.C.v = set end
    return Vector2(self.C.v)
end
function Bubble:x_velocity(set)
    if set then self.C.v.x = set end
    return tonumber(self.C.v.x)
end
function Bubble:y_velocity(set)
    if set then self.C.v.y = set end
    return tonumber(self.C.v.y)
end
function Bubble:x_position(set)
    if set then self.C.pos.x = set end
    return tonumber(self.C.pos.x)
end
function Bubble:y_position(set)
    if set then self.C.pos.y = set end
    return tonumber(self.C.pos.y)
end
function Bubble:red(set)
    if set then self.C.color.r = set end
    return tonumber(self.C.color.r)
end
function Bubble:green(set)
    if set then self.C.color.g = set end
    return tonumber(self.C.color.g)
end
function Bubble:blue(set)
    if set then self.C.color.b = set end
    return tonumber(self.C.color.b)
end
function Bubble:transformation_color(set)
    if set then self.C.trans_color = set end
    return Color(self.C.trans_color)
end
function Bubble:start_transformation(color, start_time, angle)
    self.C.trans_color = color
    self.C.trans_starttime = start_time
    self.C.trans_angle = angle
end

local mt = {
}
ParticleEntity = ffi.metatype("Particle", mt)

local mt = {
    new = function (Self)
        return ffi.gc(C.create_bubble_shader(), C.free)
    end;
    create_bubble = function (shader, color, pos, velocity, radius)
        local bubble = setmetatable({}, Bubble)
        bubble.id = C.create_bubble(shader, color, pos, velocity, radius)
        bubble.C = C.get_bubble(shader, bubble.id)
        bubble.in_transition = false
        return bubble
    end;
    draw = function (shader)
        C.bubbleshader_draw(shader)
    end;
    destroy_bubble = function (shader, id)
        C.destroy_bubble(shader, id)
    end;
}

mt.__index = mt
BubbleShader = ffi.metatype("BubbleShader", mt)

local mt = {
    new = function (Self)
        return ffi.gc(C.create_pop_shader(), C.free)
    end;
    draw = function (shader, dt)
        C.pop_draw(shader, dt)
    end;
    get_particle = function (shader, id)
        return C.pop_get_particle(shader, id)
    end;
    create_particle = function (shader, pos, color, radius)
        return C.push_particle(shader, ParticleEntity(pos, color, radius, 0, true))
    end;
    destroy_particle = function (self, id)
        local particle = self:get_particle(id)
        particle.alive = false
    end;
}
mt.__index = mt
PoppingShader = ffi.metatype("PoppingShader", mt)

local mt = {
    new = function (Self, bubbleshader)
        return ffi.gc(C.create_bg_shader(bubbleshader), C.free)
    end;
    draw = function (shader, indices)
        C.bgshader_draw(shader, ffi.new("uint64_t[10]", indices), #indices)
    end;
}
mt.__index = mt
BgShader = ffi.metatype("BgShader", mt)

math.randomseed(os.time())

dbg = function(...) print(...) return ... end

lock_global_table = function()
    setmetatable(_G, {
        __newindex = function(t, k, v)
            error("attempt to set undeclared global \""..k.."\"", 2)
        end;
    })
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

function resolution()
    local dimensions = ffi.C.get_resolution()
    return (Vector2){ dimensions.width, dimensions.height }
end
