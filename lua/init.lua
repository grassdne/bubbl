local ffi = require "ffi"
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

// Opaque types
typedef struct {} BubbleShader;
typedef struct {} PoppingShader;
typedef struct {} BgShader;

BubbleShader* create_bubble_shader(void);
PoppingShader* create_pop_shader(void);
BgShader* create_bg_shader(BubbleShader *s);

enum{ MAX_ELEMS=10 };

int create_bubble(BubbleShader *s, Color color, Vector2 position, Vector2 velocity, int radius);
void create_pop(PoppingShader *s, Vector2 pos, Color color, float rad);
void destroy_bubble(BubbleShader *s, size_t id);
int get_bubble_at_point(Vector2 pos);
Bubble *get_bubble(BubbleShader *s, size_t id);
void free(void *p);
void bubbleshader_draw(BubbleShader *s);
void pop_draw(PoppingShader *s, double dt);
void bgshader_draw(BgShader *sh, const size_t indices[MAX_ELEMS], size_t num_elems);
]]

BGSHADER_MAX_ELEMS = 10

do
    local mt = {
        __add = function(v, rhs) return Vector2(v.x + rhs.x, v.y + rhs.y) end,
        __sub = function(v, rhs) return Vector2(v.x - rhs.x, v.y - rhs.y) end,
        __mul = function(v, rhs) return Vector2(v.x * rhs, v.y * rhs) end,
        __div = function(v, rhs) return Vector2(v.x / rhs, v.y / rhs) end,
        __unm = function(v) return Vector2(-v.x, -v.y) end,
        dot = function(a, b) return a.x*b.x + a.y*b.y end,
        scale = function(v, mult) return Vector2(v.x*mult, v.y*mult) end,
        lengthsq = function(v) return v.x*v.x + v.y*v.y end,
        length = function(v) return math.sqrt(v:lengthsq()) end,
        distsq = function(a, b) return (a - b):lengthsq() end,
        dist = function(a, b) return math.sqrt(a:distsq(b)) end,
        normalize = function(v) return v / v:length() end,
        __tostring = function(v)
            return ("Vector2(%.2f, %.2f)"):format(v.x, v.y)
        end,
    }
    mt.__index = mt
    Vector2 = ffi.metatype("Vector2", mt)
end

do
    local mt = {
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
    mt.__index = mt
    Color = ffi.metatype("Color", mt)
end

do
    local mt = {
        __gc = function(bubble)
            bubble.C.alive = false
        end,
    }
    mt.__index = mt
    BubbleEntity = ffi.metatype("Bubble", mt)
end

do
    Bubble = {}
    Bubble.__index = Bubble
    Bubble.radsq = function(b) return b.C.rad*b.C.rad end
    function Bubble:delta_radius(dr)
        self.C.rad = self.C.rad + dr
    end
end

do
    local mt = {
        create_bubble = function (shader, color, pos, velocity, radius)
            local bubble = setmetatable({}, Bubble)
            bubble.id = ffi.C.create_bubble(shader, color, pos, velocity, radius)
            bubble.C = ffi.C.get_bubble(shader, bubble.id)
            return bubble
        end;
        draw = function (shader)
            ffi.C.bubbleshader_draw(shader)
        end;
        destroy_bubble = function (shader, id)
            ffi.C.destroy_bubble(shader, id)
        end;
    }

    mt.__index = mt
    BubbleShader = ffi.metatype("BubbleShader", mt)

    create_bubble_shader = function()
        return ffi.gc(ffi.C.create_bubble_shader(), ffi.C.free)
    end
end

do
    local mt = {
        create_pop = function (shader, pos, color, radius)
            ffi.C.create_pop(shader, pos, color, radius)
        end;
        draw = function (shader, dt)
            ffi.C.pop_draw(shader, dt)
        end;
    }
    mt.__index = mt
    ffi.metatype("PoppingShader", mt)

    create_pop_shader = function()
        return ffi.gc(ffi.C.create_pop_shader(), ffi.C.free)
    end
end

do
    local mt = {
        draw = function (shader, indices)
            ffi.C.bgshader_draw(shader, ffi.new("uint64_t[10]", indices), #indices)
        end;
    }
    mt.__index = mt
    ffi.metatype("BgShader", mt)

    create_bg_shader = function(bubbleshader)
        return ffi.gc(ffi.C.create_bg_shader(bubbleshader), ffi.C.free)
    end
end

KEY_SPACE = 32
KEY_APOSTROPHE = 39
KEY_COMMA = 44
KEY_MINUS = 45
KEY_PERIOD = 46
KEY_SLASH = 47
KEY_0 = 48
KEY_1 = 49
KEY_2 = 50
KEY_3 = 51
KEY_4 = 52
KEY_5 = 53
KEY_6 = 54
KEY_7 = 55
KEY_8 = 56
KEY_9 = 57
KEY_SEMICOLON = 59
KEY_EQUAL = 61
KEY_A = 65
KEY_B = 66
KEY_C = 67
KEY_D = 68
KEY_E = 69
KEY_F = 70
KEY_G = 71
KEY_H = 72
KEY_I = 73
KEY_J = 74
KEY_K = 75
KEY_L = 76
KEY_M = 77
KEY_N = 78
KEY_O = 79
KEY_P = 80
KEY_Q = 81
KEY_R = 82
KEY_S = 83
KEY_T = 84
KEY_U = 85
KEY_V = 86
KEY_W = 87
KEY_X = 88
KEY_Y = 89
KEY_Z = 90
KEY_LEFT_BRACKET = 91
KEY_BACKSLASH = 92
KEY_RIGHT_BRACKET = 93
KEY_GRAVE_ACCENT = 96
KEY_WORLD_1 = 161
KEY_WORLD_2 = 162
KEY_ESCAPE = 256
KEY_ENTER = 257
KEY_TAB = 258
KEY_BACKSPACE = 259
KEY_INSERT = 260
KEY_DELETE = 261
KEY_RIGHT = 262
KEY_LEFT = 263
KEY_DOWN = 264
KEY_UP = 265
KEY_PAGE_UP = 266
KEY_PAGE_DOWN = 267
KEY_HOME = 268
KEY_END = 269
KEY_CAPS_LOCK = 280
KEY_SCROLL_LOCK = 281
KEY_NUM_LOCK = 282
KEY_PRINT_SCREEN = 283
KEY_PAUSE = 284
KEY_F1 = 290
KEY_F2 = 291
KEY_F3 = 292
KEY_F4 = 293
KEY_F5 = 294
KEY_F6 = 295
KEY_F7 = 296
KEY_F8 = 297
KEY_F9 = 298
KEY_F10 = 299
KEY_F11 = 300
KEY_F12 = 301
KEY_F13 = 302
KEY_F14 = 303
KEY_F15 = 304
KEY_F16 = 305
KEY_F17 = 306
KEY_F18 = 307
KEY_F19 = 308
KEY_F20 = 309
KEY_F21 = 310
KEY_F22 = 311
KEY_F23 = 312
KEY_F24 = 313
KEY_F25 = 314
KEY_KP_0 = 320
KEY_KP_1 = 321
KEY_KP_2 = 322
KEY_KP_3 = 323
KEY_KP_4 = 324
KEY_KP_5 = 325
KEY_KP_6 = 326
KEY_KP_7 = 327
KEY_KP_8 = 328
KEY_KP_9 = 329
KEY_KP_DECIMAL = 330
KEY_KP_DIVIDE = 331
KEY_KP_MULTIPLY = 332
KEY_KP_SUBTRACT = 333
KEY_KP_ADD = 334
KEY_KP_ENTER = 335
KEY_KP_EQUAL = 336
KEY_LEFT_SHIFT = 340
KEY_LEFT_CONTROL = 341
KEY_LEFT_ALT = 342
KEY_LEFT_SUPER = 343
KEY_RIGHT_SHIFT = 344
KEY_RIGHT_CONTROL = 345
KEY_RIGHT_ALT = 346
KEY_RIGHT_SUPER = 347
KEY_MENU = 348

math.randomseed(os.time())

dbg = function(...) print(...) return ... end
