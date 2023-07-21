local Text = require "text"
local Effect = require "effects"

local GENERATE_FRAMES = false
local PERIOD = 10
local MAX_PERIOD = 5


local VAR = {
    TEXT = "bubbl",
    POSITION = "left",
    COLOR = Color.Hsl(300, 1.0, 0.5),
    COLORING = "solid",
    LIFETIME = 4,
    SPEED = 400,
    LIMITER = "speed",
}

local particles
local start_time
local background = CreateCanvas { { Color.Hsl(0, 1, 0.01) } }
local effect

local Update = function (dt)
    background:draw()
    effect:Update(dt)
end


local BuildText = function ()
    effect = Effect:Build(VAR.TEXT, {
        color=VAR.COLORING == "solid" and VAR.COLOR or VAR.COLORING,
        position=VAR.POSITION,
        lifetime=VAR.LIMITER == "lifetime" and VAR.LIFETIME or nil,
        speed=VAR.LIMITER == "speed" and VAR.SPEED or nil,
    })
end

return {
    title = "Text Effects",

    tweak = {
        vars = VAR,
        { id="TEXT", name="Text", type="string", callback=BuildText },
        { id="POSITION", name="From", type="options", callback=BuildText, options = {
            "left", "random", "above", "constant",
        }},
        { id="LIMITER", name="Limiter", type="options", callback=BuildText, options = {
            "lifetime", "speed"
        } },
        { id="LIFETIME", name="Lifetime", type="range", min=0.25, max=6, callback=BuildText },
        { id="SPEED", name="Speed", type="range", min=50, max=2000, callback=BuildText },
        { id="COLORING", name="Coloring", type="options", callback=BuildText, options = {
            "rainbow", "solid",
        } },
        { id="COLOR", name="Solid Color", type="color", callback=BuildText },
    },

    OnStart = BuildText,

    Draw = function (dt)
        Update(dt)
        -- TODO: GIFs
        -- GifAddFrame("test.gif", i, i / FPS)
    end,
}
