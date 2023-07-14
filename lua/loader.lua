local loader = {}

local FileExists = function (name)
    local f = io.open(name)
    if f then io.close(f) end
    return f ~= nil
end

loader.LoadModule = function (module)
    if TheServer then TheServer:close() end -- hot reload
    TheServer = require "server"

    local module_name_lua = "modules/"..module..".lua"
    local module_name_c = "./modules/"..module..".so"
    if FileExists(module_name_lua) then
        local mod, err = loadfile(module_name_lua)
        if not mod then
            print("Error loading module "..module)
            print(err)
            return;
        end
        -- TODO: DEPRECATED: modules putting info in global table
        loader.active_module = mod() or _G
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
        loader.active_module = {
            Draw = function(dt)
                lib.on_update(dt)
            end,
        }
    else
        print("Could not find module "..module)
        print("Tried: "..module_name_lua)
        print("       "..module_name_c)
        print()
        print(string.format("Usage: %s elastic|rainbow|svg|swirl", arg[0]))
        return;
    end

    loader.active_module.source = module
    loader.Callback("OnStart")
    if loader.active_module.tweak then
        TheServer:MakeConfig(loader.active_module.tweak)
    end
    return loader.active_module
end

loader.HotReload = function (module)
    ClearShaderCache()
    -- Unlock global table
    setmetatable(_G, nil)
    package.loaded["server"] = nil
    loader.LoadModule(assert(loader.active_module and loader.active_module.source))
end

-- optional, asyncronous, protected call
loader.Callback = function(name, ...)
    local fn = rawget(loader.active_module, name)
    if fn then
        local co = coroutine.create(fn)
        local ok, err = coroutine.resume(co, ...)
        if not ok then
            print("Error inside "..name.." callback!")
            print(err)
        end
    end
end

return loader
