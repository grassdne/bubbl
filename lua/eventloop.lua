local ffi = require "ffi"
local C = ffi.C

local TICK_TIME = 1/30

local OptionalCallback = function(fn, ...)
    if fn then fn(...) end
end

local last_tick = math.floor(Seconds() / TICK_TIME)
local last_time = Seconds()
while not C.should_quit() do
    local now = Seconds()
    local dt = now - last_time
    local tick = math.floor(now / TICK_TIME)
    last_tick = tick
    last_time = now

    assert(OnUpdate, "missing OnUpdate callback")
    ClearScreen()
    OnUpdate(dt)
    FlushRenderers()
    C.SDL_GL_SwapWindow(window)

    for event in NextEvent do
        if event.type == "EVENT_KEY" then
            OptionalCallback(OnKey, ffi.string(event.key.name), event.key.is_down)

        elseif event.type == "EVENT_MOUSEBUTTON" then
            if event.mousebutton.is_down then
                OptionalCallback(OnMouseDown, event.mousebutton.position:unpack())
            else
                OptionalCallback(OnMouseUp, event.mousebutton.position:unpack())
            end

        elseif event.type == "EVENT_MOUSEMOTION" then
            OptionalCallback(OnMouseMove, event.mousemotion.position:unpack())

        elseif event.type == "EVENT_MOUSEWHEEL" then
            OptionalCallback(OnMouseWheel, event.mousewheel.scroll:unpack())

        elseif event.type == "EVENT_RESIZE" then
            window_width = event.resize.width
            window_height = event.resize.height
            OptionalCallback(OnWindowResize, window_width, window_height)
        end
    end
end
