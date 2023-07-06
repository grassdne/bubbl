local ffi = require "ffi"

---@param file_name string
ReadEntireFile = function (file_name)
    local file, err = io.open(file_name)
    if not file then return false, err end
    local result = file:read("*a")
    file:close()
    return result
end

-- Remove preprocessor directives
local content = ('\n'..assert(ReadEntireFile("src/api.h")))
                :gsub("\n%s*%#[^\n]*", "")
ffi.cdef(content)


math.randomseed(os.time())

package.path = "./lua/?.lua;" .. package.path

require "api"
require "scheduler"

resolution = Vector2(1600, 900)

window = CreateWindow("Bubble", resolution:unpack())

OnQuit = function ()
    -- Finish any remaining GIFs
    GifFinish()
end
