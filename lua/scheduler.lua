-- Coroutine-based scheduler
-- tasks table maps tick number to task coroutine.
-- All tasks are kept as Lua coroutines.
-- To yield from a task and resume 5 seconds later:
--     coroutine.yield(5)
-- To yield from a task and resume the next tick:
--     coroutine.yield()


TICK_TIME = 1/30

local tasks = {}
local current_tick = 0
local last_tick = 0

UpdateCurrentTick = function()
    current_tick = math.floor(Seconds() / TICK_TIME)
end

ScheduleCo = function(co, time)
    -- Must be at least the next tick
    local tick = current_tick + math.max(1, math.floor(time / TICK_TIME))
    tasks[tick] = tasks[tick] or {}
    table.insert(tasks[tick], co)
end
ScheduleFn = function(fn, time)
    ScheduleCo(coroutine.create(fn), time)
end

RunScheduler = function()
    for tick=last_tick+1, current_tick do
        if tasks[tick] then
            for _,co in ipairs(tasks[tick]) do
                assert(coroutine.resume(co))
            end
            tasks[tick] = nil
        end
    end
    last_tick = current_tick
end

Suspend = function(delay)
    local co = assert(coroutine.running(), "must be called within running coroutine")
    ScheduleCo(co, delay or 0)
    coroutine.yield()
end
