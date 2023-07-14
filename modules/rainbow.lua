local PERIOD = 4.5
local MIN_RADIUS = 10
local MAX_RADIUS = 20
local MAX_ATTAINED_RADIUS = 40
local SPACING = 22
local WRAPAROUND_BUFFER = 3
local MOUSE_EFFECT_RADIUS = 150
local SIZE_DELTA = 75

local START_POS_RIGHT = WRAPAROUND_BUFFER * SPACING
local END_POS_LEFT = -WRAPAROUND_BUFFER * SPACING

local VAR = {
    RADIUS_ADDEND = 0,
    SPEED = 1/PERIOD,
}

local particles = {}

-- radius and y position are randomized
-- but color and x position are passed in
local gen_particle = function (color, x_position)
    return {
        color = color,
        radius = random.minmax(MIN_RADIUS, MAX_RADIUS),
        position = Vector2(x_position, resolution.y * math.random())
    }
end

-- This is the only place we actually add new particles
local gen_particle_field = function ()
    -- The x positions are in neat columns
    -- Adding noise just made it look like a mess
    for x=END_POS_LEFT+SPACING, resolution.x + START_POS_RIGHT, SPACING do
        for i=0, resolution.y / SPACING do
            table.insert(particles, gen_particle(Color.hsl(x/resolution.x*360, 1, 0.5), x))
        end
    end
end

local last_mouse_position = MousePosition()

gen_particle_field()

return {
    title = "🌈🌈🌈",

    tweak = {
        vars = VAR,
        { name="Size", id="RADIUS_ADDEND", type="range", min=-MIN_RADIUS, max=MAX_RADIUS },
        { name="Speed", id="SPEED", type="range", min=0, max=2 },
    },

    OnWindowResize = function(w, h)
        -- Clear particles
        particles = {}
        gen_particle_field()
    end,

    Draw = function(dt)
        -- Update and draw particles
        for i,part in ipairs(particles) do
            local length = resolution.x + START_POS_RIGHT - END_POS_LEFT
            part.position:delta_x(-length * VAR.SPEED * dt)
            if part.position.x < END_POS_LEFT then
                -- Jump back to the other end
                particles[i] = gen_particle(part.color, part.position.x + length)
            end
            RenderPop(part.position, part.color, part.radius + VAR.RADIUS_ADDEND, 0)
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
                    if dist < MOUSE_EFFECT_RADIUS then
                        local proximity = 1 - dist / MOUSE_EFFECT_RADIUS
                        part.radius = math.min(MAX_ATTAINED_RADIUS, part.radius + SIZE_DELTA * dt)
                    end
                end
            end
            last_mouse_position = mouse
        end
}
