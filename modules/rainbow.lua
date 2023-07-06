Title "🌈🌈🌈"

local START_POS_RIGHT = RAINBOW.WRAPAROUND_BUFFER * RAINBOW.SPACING
local END_POS_LEFT = -RAINBOW.WRAPAROUND_BUFFER * RAINBOW.SPACING

particles = {}

-- radius and y position are randomized
-- but color and x position are passed in
local gen_particle = function (color, x_position)
    return {
        color = color,
        radius = random.minmax(RAINBOW.MIN_RADIUS, RAINBOW.MAX_RADIUS),
        position = Vector2(x_position, resolution.y * math.random())
    }
end

-- This is the only place we actually add new particles
local gen_particle_field = function ()
    -- The x positions are in neat columns
    -- Adding noise just made it look like a mess
    for x=END_POS_LEFT+RAINBOW.SPACING, resolution.x + START_POS_RIGHT, RAINBOW.SPACING do
        for i=0, resolution.y / RAINBOW.SPACING do
            table.insert(particles, gen_particle(Color.hsl(x/resolution.x*360, 1, 0.5), x))
        end
    end
end

local last_mouse_position = MousePosition()

OnUpdate = function(dt)
    -- Update and draw particles
    for i,part in ipairs(particles) do
        local length = resolution.x + START_POS_RIGHT - END_POS_LEFT
        part.position:delta_x(-length / RAINBOW.PERIOD * dt)
        if part.position.x < END_POS_LEFT then
            -- Jump back to the other end
            particles[i] = gen_particle(part.color, part.position.x + length)
        end
        RenderPop(part.position, part.color, part.radius, 0)
    end

    -- Grow particles in proximity to cursor
    local mouse = MousePosition()
    -- TODO: We don't want to do anything if the mouse is outside the window
    -- the following guard doesn't actually do any good
    if (mouse.x ~= last_mouse_position.x or mouse.y ~= last_mouse_position.y)
        and mouse.x > 0 and mouse.x < resolution.x
        and mouse.y > 0 and mouse.y < resolution.y
    then
        for _,part in ipairs(particles) do
            local dist = mouse:dist(part.position)
            if dist < RAINBOW.MOUSE_EFFECT_RADIUS then
                local proximity = 1 - dist / RAINBOW.MOUSE_EFFECT_RADIUS
                part.radius = math.min(RAINBOW.MAX_ATTAINED_RADIUS, part.radius + RAINBOW.SIZE_DELTA * dt)
            end
        end
    end
    last_mouse_position = mouse
end

OnWindowResize = function(w, h)
    -- Clear particles
    particles = {}
    gen_particle_field()
end

LockTable(_G)

gen_particle_field()
