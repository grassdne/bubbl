local ffi = require "ffi"
local C = ffi.C

-- OnStart, OnKey, OnMouseDown, etc callbacks are asyncronous coroutines!
-- You can yield to pause for a certain amount of time or the next frame
local OptionalCallback = function(name, ...)
    local fn = rawget(_G, name)
    if fn then
        local co = coroutine.create(fn)
        local ok, err = coroutine.resume(co, ...)
        if not ok then
            print("Error inside "..name.." callback!")
            print(err)
        end
    end
end

UpdateCurrentTick()
local last_time = Seconds()

OptionalCallback("OnStart", false)

local OnKey = function(key, is_down)
    if key == 'R' and is_down then
        ClearShaderCache()
        -- Unlock global table
        setmetatable(_G, nil)
        for k,v in pairs(package.loaded) do package.loaded[k] = nil end
        require 'config'
        OptionalCallback("OnStart", true)
    end
    OptionalCallback("OnKey", key, is_down)
end

while not ShouldQuit() do
    local now = Seconds()
    local dt = now - last_time
    UpdateCurrentTick()
    last_time = now

    assert(Draw, "missing Draw callback")
    ClearScreen()
    local ok, err = pcall(Draw, dt)
    if not ok then
        print("Error inside Draw!")
        print(err)
        print("Disabling Draw... fix it and hot reload, or restart.")
        Draw = function() end
    end
    FlushRenderers()
    UpdateScreen(window)

    for event in PendingEvents() do
        if event.type == "EVENT_KEY" then
            OnKey(ffi.string(event.key.name), event.key.is_down)

        elseif event.type == "EVENT_MOUSEBUTTON" then
            if event.mousebutton.is_down then
                OptionalCallback("OnMouseDown", event.mousebutton.position:unpack())
            else
                OptionalCallback("OnMouseUp", event.mousebutton.position:unpack())
            end

        elseif event.type == "EVENT_MOUSEMOTION" then
            OptionalCallback("OnMouseMove", event.mousemotion.position:unpack())

        elseif event.type == "EVENT_MOUSEWHEEL" then
            OptionalCallback("OnMouseWheel", event.mousewheel.scroll:unpack())

        elseif event.type == "EVENT_RESIZE" then
            resolution.x = event.resize.width
            resolution.y = event.resize.height
            OptionalCallback("OnWindowResize", resolution.x, resolution.y)
        end
    end

    RunScheduler()
end

OnQuit()
