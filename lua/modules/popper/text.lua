local Text = require "text"

local TEXT_ANIM_TIME = 0.5
local TEXT_COLOR = Color.Hsl(260, 1, 0.4, 0.8)

local GenText = function (opts)
    Text.SetFont("Lora-VariableFont")
    local particles = Text.BuildParticlesWithWidth(opts.str, opts.width)
    particles.base_position = Vector2(1 - opts.width, -particles.height) / 2
    return random.shuffle(particles)
end

local RenderParticle = function (position, radius)
    local base = Vector2(0, resolution.y/2)
    RenderPop(position * resolution.x + base, TEXT_COLOR, radius * resolution.x)
end

return {
    Build = function (self, build_opts)
        self.particles = {}
        self.next = nil
        -- Keeping a single element queue keeps us from needing
        -- to interrupt the current transition
        self.queue = nil
        self:QueueTransform(build_opts)
    end;

    Update = function (self, dt)
        if self.queue and not self.next then
            -- Move up queued transition
            self.next = self.queue
            self.queue = nil
            self.next.transition_start = Seconds()
        end

        if not self.next then
            -- No active animation
            for i=1, #self.particles do
                RenderParticle(self.particles.base_position + self.particles[i].offset, self.particles[i].radius)
            end
        else -- Perform transition animation
            -- There is no mutated state during an animation
            -- only an interpolation based on t
            local t = (Seconds() - self.next.transition_start) / TEXT_ANIM_TIME

            -- "Move" particles from self.particles to self.next
            for i=1, math.min(#self.particles, #self.next) do
                local position = Vector2.Lerp(self.particles.base_position + self.particles[i].offset, self.next.base_position + self.next[i].offset, t)
                local radius = Lerp(self.particles[i].radius, self.next[i].radius, t)
                RenderParticle(position, radius)
            end

            -- Destroy excess particles
            -- when #self.particles > #self.next
            for i=#self.next+1, #self.particles do
                local radius = Lerp(self.particles[i].radius, 0, t)
                RenderParticle(self.particles.base_position + self.particles[i].offset, radius)
            end

            -- Build new particles
            -- when #self.particles < #self.next
            for i=#self.particles+1, #self.next do
                local radius = Lerp(0, self.next[i].radius, t)
                RenderParticle(self.next.base_position + self.next[i].offset, radius)
            end

            local transition_completed = t > 1
            if transition_completed then
                self.particles = self.next
                self.next = nil
            end
        end
        FlushRenderers()
    end;

    QueueTransform = function (self, build_opts)
        local new = GenText(build_opts)
        self.queue = new
    end;
}
