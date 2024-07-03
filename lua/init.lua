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

-- Modules
package.path = "./lua/?.lua;" .. "./lua/?/init.lua;" .. package.path
-- Dependencies
package.path = "./deps/lua_modules/share/lua/5.1/?.lua;" .. package.path
package.cpath = "./deps/lua_modules/lib64/lua/5.1/?.so;" .. package.cpath

require "api"
require "scheduler"
require "http.server"

resolution = Vector2(800, 600)

OnQuit = function ()
    -- Finish any remaining GIFs
    GifFinish()
end

-- Strict global table
do
    local explicit_globals = {}

    Global = function (name)
        explicit_globals[name] = true
    end

    setmetatable(_G, {
        __newindex = function(t, k, v)
            if explicit_globals[k] then rawset(_G, k, v) return end
            error("attempt to set undeclared global \""..k.."\"", 2)
        end;
        __index = function(t, k)
            if explicit_globals[k] then return nil end
            error("attempt to get undeclared global \""..k.."\"", 2)
        end;
    })

end

Global "TheServer"
Global "window"
window = CreateWindow("bubbl", resolution:Unpack())
