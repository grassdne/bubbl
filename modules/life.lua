Title "Game of Life"

local COLOR = Color.hsl(0, 1.0, 0)
local ROWS = 75
local COLS = 75
local DENSITY = 0.3
local INTERVAL = 0.05

local CountNeighbors = function (field, row, col, state)
    local count = 0
    for r=row-1, row+1 do
        for c=col-1, col+1 do
            if (r ~= row or c ~= col) and field[r] and field[r][c] == state then
                count = count + 1
            end
        end
    end
    return count
end

local NextGeneration = function (current_field)
    local next_field = {}
    for row=1, ROWS do
        next_field[row] = {}
        for col=1, COLS do
            local state = current_field[row][col]
            local neighbors = CountNeighbors(current_field, row, col, "alive")
            if neighbors == 3 or state == "alive" and neighbors == 2 then
                next_field[row][col] = "alive"
            else
                next_field[row][col] = "dead"
            end

        end
    end
    return next_field
end

local field = {}

OnStart = function()
    for row=1, ROWS do
        field[row] = {}
        for col=1, COLS do
            field[row][col] = math.random() < 0.3 and "alive" or "dead"
        end
    end
    while true do
        Suspend(INTERVAL)
        field = NextGeneration(field)
    end
end

OnUpdate = function(dt)
    local spacing_x = window_width / COLS
    local spacing_y = window_height / ROWS
    local size = math.min(spacing_x, spacing_y) / 2
    for row=1, ROWS do
        for col=1, COLS do
            local x = col * spacing_x - size
            local y = row * spacing_y - size
            if field[row][col] == "alive" then
                RenderSimple(Vector2(x, y), COLOR, size)
            end
        end
    end
end

