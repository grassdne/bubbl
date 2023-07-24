local anim = {}

local TimePassed = function (self)
    return Seconds() - self.start_time
end

local NextParticle = function (self, i)
    i = i + 1
    local initial = self.initial[i]
    local final = self.final[i]
    if initial then
        local t = math.min(1, self.time / initial.time)
        local position = Lerp(initial.position, final.position, t)
        local color = Lerp(initial.color, final.color, t)
        local radius = Lerp(initial.radius, final.radius, t)
        return i, position, color, radius
    end
end

local methods = Parent {
    Interpolate = function (self, time)
        self.time = time or TimePassed(self)
        return NextParticle, self, 0
    end,
    IsComplete = function (self, time)
        time = time or TimePassed(self)
        return time >= self.length
    end
}

anim.Build = function (initial, final)
    local state = setmetatable({}, methods)
    assert(#initial == #final)
    state.count = #initial
    state.initial = initial
    state.final = final
    state.start_time = Seconds()
    state.length = 0
    for i,v in ipairs(state.initial) do
        if v.time > state.length then state.length = v.time end
    end
    return state
end

return anim
