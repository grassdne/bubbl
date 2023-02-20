local DEFAULT = "swirl"

local i = 0
local NextArg = function()
    i = i + 1
    return arg[i]
end

local program = NextArg()
if not program then
    print(string.format("usage: %s elastic|rainbow|svg|swirl", arg[0]))
    program = DEFAULT
end

ELASTIC = {
    STARTING_BUBBLE_COUNT = 10,
    BUBBLE_SPEED_BASE = 200,
    BUBBLE_SPEED_VARY = 225,
    BUBBLE_RAD_BASE = 30,
    BUBBLE_RAD_VARY = 25,
    MAX_GROWTH = 200,
    MIN_GROWTH_RATE = 50,
    MAX_GROWTH_RATE = 225,
    TRANS_IMMUNE_PERIOD = 1,
    TRANS_TIME = 1,
    POP_EXPAND_MULT = 2.0,
    POP_LAYER_WIDTH = 10.0,
    POP_PARTICLE_LAYOUT = 5,
    POP_LIFETIME = 1.0,
    POP_PT_RADIUS = 7.0,
    POP_PT_RADIUS_DELTA = 4.0,
    BUBBLE_HUE = 0.9,
    BUBBLE_LIGHTNESS = 0.5,
    TRANSFORM_TIME = 1.0,
}

RAINBOW = {
    PERIOD = 4.5, -- Time for one revolution
    MIN_RADIUS = 10,
    MAX_RADIUS = 20,
    MAX_ATTAINED_RADIUS = 40,
    SPACING = 22,
    WRAPAROUND_BUFFER = 3,
    MOUSE_EFFECT_RADIUS = 300,
    SIZE_DELTA = 40,
}

SVGEDITOR = {
    FILE = NextArg() or "img.svg",
    COLOR = WEBCOLORS.PURPLE,
}

local ok = pcall(require, "modules/"..program)
if not ok then
    print("unable to find module "..program)
    os.exit(1)
end
