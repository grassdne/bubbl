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

int create_bubble(Color color, Vector2 position, Vector2 velocity, int radius);
void create_pop(Vector2 pos, Color color, float rad);
void destroy_bubble(size_t id);
int get_bubble_at_point(Vector2 pos);

Bubble *get_bubble(size_t id);
]]

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
    function Bubble.new(color, pos, velocity, radius)
        local self = setmetatable({}, Bubble)
        self.id = ffi.C.create_bubble(color, pos, velocity, radius)
        self.C = ffi.C.get_bubble(self.id)
        return self
    end
end

KEY_SPACE = 32

math.randomseed(os.time())

dbg = function(...) print(...) return ... end
