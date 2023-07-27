local loader = {}

local FileExists = function (name)
    local f = io.open(name)
    if f then io.close(f) end
    return f ~= nil
end


loader.LoadModule = function (module_source_file)
    TheServer = require "server"
    local module

    local module_name_lua = "modules/"..module_source_file..".lua"
    local module_name_c = "./modules/"..module_source_file..".so"
    if FileExists(module_name_lua) then
        local mod, err = loadfile(module_name_lua)
        if not mod then
            Warning("Error loading module_source_file ", module_source_file, "\n", err)
            return;
        end
        local ok, result = xpcall(mod, debug.traceback)
        if not ok then
            Warning("Error starting module ", module_source_file, "\n", result)
            return;
        end
        module = result
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
        module = {
            Draw = function(dt)
                lib.on_update(dt)
            end,
        }
    else
        print("Could not find module "..module_source_file)
        print("Tried: "..module_name_lua)
        print("       "..module_name_c)
        print()
        print(string.format("Usage: %s elastic|rainbow|svg|swirl", arg[0]))
        return;
    end

    if module.resolution then
        Size(module.resolution:Unpack())
    end
    module.source = module_source_file

    TheServer:MakeConfig(module.tweak)
    local title = module.title
    local size = module.resolution
    if title then Title(title) end
    if size then Size(size:Unpack()) end

    return module
end

loader.HotReload = function (module)
    ClearShaderCache()
    -- Unlock global table
    setmetatable(_G, nil)
    --package.loaded["server"] = nil
    package.loaded["loader"] = nil
    package.loaded["effects"] = nil
    package.loaded["text"] = nil
    local m = loader.LoadModule(assert(loader.active_module and loader.active_module.source))
    if m then
        loader.active_module = m
    else
        Warning("Hot reload failed")
    end
    loader.Callback("OnStart")

end

loader.Start = function (module)
    loader.active_module = loader.LoadModule(module)
    if not loader.active_module then
        os.exit(1);
    end
    loader.Callback("OnStart")
end

-- optional, asyncronous, protected call
loader.Callback = function(name, ...)
    local fn = loader.active_module[name]
    if fn then
        local co = coroutine.create(fn)
        local ok, err = coroutine.resume(co, ...)
        if not ok then
            Warning("Error inside ", name, " callback!\n", debug.traceback(co, err))
        end
    end
end

return loader
