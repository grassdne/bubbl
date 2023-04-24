-- I'm not sure what this is right now
-- but it loads the module and maybe provides its constants
-- and interprets command-line arguments

local DEFAULT_MODULE = "elasticbubbles"

local i = 0
NextArg = function()
    i = i + 1
    return arg[i]
end

local module = NextArg() or DEFAULT_MODULE

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
    MOUSE_EFFECT_RADIUS = 150,
    SIZE_DELTA = 75,
}

local FileExists = function (name)
    local f = io.open(name)
    if f then io.close(f) end
    return f ~= nil
end

local module_name_lua = "modules/"..module..".lua"
local module_name_c = "./modules/"..module..".so"
if FileExists(module_name_lua) then
    local mod, err = loadfile(module_name_lua)
    if not mod then
        print("Error loading module "..module)
        print(err)
        return;
    end
    mod()
    package.loaded[module_name_lua] = nil
elseif FileExists(module_name_c) then
    local ffi = require "ffi"
    -- Little hack to unload the cached c library
    -- there is no ffi.unload but the __gc metamethod is an unload
    -- and to force a hot reload we need to unload first
    if _loaded_c_module then
        getmetatable(_loaded_c_module).__gc(_loaded_c_module)
    end
    local lib = ffi.load(module_name_c)
    _loaded_c_module = lib
    ffi.cdef("void init(Window *window)")
    lib.init(window)
    OnUpdate = function(dt)
        lib.on_update(dt)
    end
else
    print("Could not find module "..module)
    print("Tried: "..module_name_lua)
    print("       "..module_name_c)
    print()
    print(string.format("Usage: %s elastic|rainbow|svg|swirl", arg[0]))
    return;
end
