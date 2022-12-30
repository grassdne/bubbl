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
double glfwGetTime(void);
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

local mt = {
}
ParticleEntity = ffi.metatype("Particle", mt)

local mt = {
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

create_bubble_shader = function()
    return ffi.gc(C.create_bubble_shader(), C.free)
end

local mt = {
    draw = function (shader, dt)
        C.pop_draw(shader, dt)
    end;
    get_particle = function (shader, id)
        return C.pop_get_particle(shader, id)
    end;
    push_particle = function (shader, particle)
        return C.push_particle(shader, particle)
    end;
    destroy_particle = function (self, id)
        local particle = self:get_particle(id)
        particle.alive = false
    end;
}
mt.__index = mt
ffi.metatype("PoppingShader", mt)

create_pop_shader = function()
    return ffi.gc(C.create_pop_shader(), C.free)
end

local mt = {
    draw = function (shader, indices)
        C.bgshader_draw(shader, ffi.new("uint64_t[10]", indices), #indices)
    end;
}
mt.__index = mt
ffi.metatype("BgShader", mt)

create_bg_shader = function(bubbleshader)
    return ffi.gc(C.create_bg_shader(bubbleshader), C.free)
end

KEY = {}
KEY.SPACE = 32
KEY.APOSTROPHE = 39
KEY.COMMA = 44
KEY.MINUS = 45
KEY.PERIOD = 46
KEY.SLASH = 47
KEY.NUM_0 = 48
KEY.NUM_1 = 49
KEY.NUM_2 = 50
KEY.NUM_3 = 51
KEY.NUM_4 = 52
KEY.NUM_5 = 53
KEY.NUM_6 = 54
KEY.NUM_7 = 55
KEY.NUM_8 = 56
KEY.NUM_9 = 57
KEY.SEMICOLON = 59
KEY.EQUAL = 61
KEY.A = 65
KEY.B = 66
KEY.C = 67
KEY.D = 68
KEY.E = 69
KEY.F = 70
KEY.G = 71
KEY.H = 72
KEY.I = 73
KEY.J = 74
KEY.K = 75
KEY.L = 76
KEY.M = 77
KEY.N = 78
KEY.O = 79
KEY.P = 80
KEY.Q = 81
KEY.R = 82
KEY.S = 83
KEY.T = 84
KEY.U = 85
KEY.V = 86
KEY.W = 87
KEY.X = 88
KEY.Y = 89
KEY.Z = 90
KEY.LEFT_BRACKET = 91
KEY.BACKSLASH = 92
KEY.RIGHT_BRACKET = 93
KEY.GRAVE_ACCENT = 96
KEY.WORLD_1 = 161
KEY.WORLD_2 = 162
KEY.ESCAPE = 256
KEY.ENTER = 257
KEY.TAB = 258
KEY.BACKSPACE = 259
KEY.INSERT = 260
KEY.DELETE = 261
KEY.RIGHT = 262
KEY.LEFT = 263
KEY.DOWN = 264
KEY.UP = 265
KEY.PAGE_UP = 266
KEY.PAGE_DOWN = 267
KEY.HOME = 268
KEY.END = 269
KEY.CAPS_LOCK = 280
KEY.SCROLL_LOCK = 281
KEY.NUM_LOCK = 282
KEY.PRINT_SCREEN = 283
KEY.PAUSE = 284
KEY.F1 = 290
KEY.F2 = 291
KEY.F3 = 292
KEY.F4 = 293
KEY.F5 = 294
KEY.F6 = 295
KEY.F7 = 296
KEY.F8 = 297
KEY.F9 = 298
KEY.F10 = 299
KEY.F11 = 300
KEY.F12 = 301
KEY.F13 = 302
KEY.F14 = 303
KEY.F15 = 304
KEY.F16 = 305
KEY.F17 = 306
KEY.F18 = 307
KEY.F19 = 308
KEY.F20 = 309
KEY.F21 = 310
KEY.F22 = 311
KEY.F23 = 312
KEY.F24 = 313
KEY.F25 = 314
KEY.KP_0 = 320
KEY.KP_1 = 321
KEY.KP_2 = 322
KEY.KP_3 = 323
KEY.KP_4 = 324
KEY.KP_5 = 325
KEY.KP_6 = 326
KEY.KP_7 = 327
KEY.KP_8 = 328
KEY.KP_9 = 329
KEY.KP_DECIMAL = 330
KEY.KP_DIVIDE = 331
KEY.KP_MULTIPLY = 332
KEY.KP_SUBTRACT = 333
KEY.KP_ADD = 334
KEY.KP_ENTER = 335
KEY.KP_EQUAL = 336
KEY.LEFT_SHIFT = 340
KEY.LEFT_CONTROL = 341
KEY.LEFT_ALT = 342
KEY.LEFT_SUPER = 343
KEY.RIGHT_SHIFT = 344
KEY.RIGHT_CONTROL = 345
KEY.RIGHT_ALT = 346
KEY.RIGHT_SUPER = 347
KEY.MENU = 348

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
