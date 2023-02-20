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
                local _, result = assert(coroutine.resume(co))
                if coroutine.status(co) == "suspended" then
                    ScheduleCo(co, result or 0)
                end
            end
            tasks[tick] = nil
        end
    end
end
