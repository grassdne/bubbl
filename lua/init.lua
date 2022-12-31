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
