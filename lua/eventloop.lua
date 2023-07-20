local loader = require "loader"
local DEFAULT_MODULE = "elasticbubbles"

local ffi = require "ffi"
local C = ffi.C

-- OnStart, OnKey, OnMouseDown, etc callbacks are asyncronous coroutines!
-- You can yield to pause for a certain amount of time or the next frame

UpdateCurrentTick()
local last_time = Seconds()

local OnKey = function(key, is_down)
    if key == 'R' and is_down then
        loader.HotReload()
    end
    loader.Callback("OnKey", key, is_down)
end

local draw

loader.LoadModule(arg[1] or DEFAULT_MODULE)

while not ShouldQuit() do
    local now = Seconds()
    local dt = now - last_time
    UpdateCurrentTick()
    last_time = now

    ClearScreen()

    RunScheduler()
    TheServer:Update()

    draw = draw or coroutine.create(assert(loader.active_module.Draw, "module missing Draw callback"))
    local ok, err = coroutine.resume(draw, dt)

    if not ok then
        print("Error inside Draw!")
        print(err)
        print("Disabling Draw... fix it and hot reload, or restart.")
        Draw = function() end
    end
    -- restart Draw function next frame, unless this one is unfinished
    if coroutine.status(draw) == "dead" then draw = nil end

    FlushRenderers()
    UpdateScreen(window)

    for event in PendingEvents() do
        if event.type == "EVENT_KEY" then
            OnKey(ffi.string(event.key.name), event.key.is_down)

        elseif event.type == "EVENT_MOUSEBUTTON" then
            if event.mousebutton.is_down then
                loader.Callback("OnMouseDown", event.mousebutton.position:unpack())
            else
                loader.Callback("OnMouseUp", event.mousebutton.position:unpack())
            end

        elseif event.type == "EVENT_MOUSEMOTION" then
            loader.Callback("OnMouseMove", event.mousemotion.position:unpack())

        elseif event.type == "EVENT_MOUSEWHEEL" then
            loader.Callback("OnMouseWheel", event.mousewheel.scroll:unpack())

        elseif event.type == "EVENT_RESIZE" then
            resolution.x = event.resize.width
            resolution.y = event.resize.height
            loader.Callback("OnWindowResize", resolution.x, resolution.y)
        end
    end
end

OnQuit()
