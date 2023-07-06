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
    Draw = function(dt)
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
