ELASTICBUBBLES = {
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
    MIN_RADIUS = 13,
    MAX_RADIUS = 26,
    MAX_ATTAINED_RADIUS = 50,
    SPACING = 30,
    WRAPAROUND_BUFFER = 3,
    MOUSE_EFFECT_RADIUS = 300,
    SIZE_DELTA = 55,
}

SVGEDITOR = {
    FILE = "img.svg",
    COLOR = WEBCOLORS.RED,
}

-----------------------
--- Elastic Bubbles ---
-----------------------
-- Click and hold to create a bubble
-- Click a bubble to pop it
--require "elasticbubbles"

-----------------
--- Rainbow 1 ---
-----------------
--require "rainbow"

require "svgeditor"
