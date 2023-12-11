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
    elseif key == 'S' and is_down then
        Screenshot(loader.active_module.source..".png")
    end
    loader.Callback("OnKey", key, is_down)
end

local draw

loader.Start(arg[1] or DEFAULT_MODULE)

while not ShouldQuit() do
    local now = Seconds()
    local dt = now - last_time
    UpdateCurrentTick()
    last_time = now

    StartDrawing()

    RunScheduler()
    TheServer:Update()

    draw = draw or coroutine.create(assert(loader.active_module.Draw, "module missing Draw callback"))
    local ok, err = coroutine.resume(draw, dt)

    if not ok then
        Warning("Error inside Draw!\n", debug.traceback(draw, err))
        Warning("Disabling Draw... fix it and hot reload, or restart.")
        loader.active_module = {
            source = loader.active_module.source,
            Draw = function ()
                local text = require "text"
                text.PutstringWithWidth(Vector2(0, 0), err, resolution.x, WEBCOLORS.RED)
            end
        }
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
                loader.Callback("OnMouseDown", event.mousebutton.position:Unpack())
            else
                loader.Callback("OnMouseUp", event.mousebutton.position:Unpack())
            end

        elseif event.type == "EVENT_MOUSEMOTION" then
            loader.Callback("OnMouseMove", event.mousemotion.position:Unpack())

        elseif event.type == "EVENT_MOUSEWHEEL" then
            loader.Callback("OnMouseWheel", event.mousewheel.scroll:Unpack())

        elseif event.type == "EVENT_RESIZE" then
            resolution.x = event.resize.width
            resolution.y = event.resize.height
            loader.Callback("OnWindowResize", resolution.x, resolution.y)
        end
    end
end

OnQuit()
