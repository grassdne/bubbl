#!/usr/bin/env lua

local server = {}

--[[
A simple HTTP server

If a request is not a HEAD method, then reply with "Hello world!"

Usage: lua examples/server_hello.lua [<port>]
]]

local port = 36373

local http_server = require "http.server"
local http_headers = require "http.headers"

local BuildHeaders = function (stream, status, content_type, close)
    if close == nil then close = false end

    local res_headers = http_headers.new()
    res_headers:append(":status", tostring(status))
    res_headers:append("content-type", content_type)

    assert(stream:write_headers(res_headers, close))
end

local function reply(myserver, stream) -- luacheck: ignore 212
    -- Read in headers
    local req_headers = assert(stream:get_headers())
    local req_method = req_headers:get ":method"

    local path = req_headers:get(":path") or ""
    -- Log request to stdout
    assert(io.stdout:write(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s"\n',
        os.date("%d/%b/%Y:%H:%M:%S %z"),
        req_method or "",
        path,
        stream.connection.version,
        req_headers:get("referer") or "-",
        req_headers:get("user-agent") or "-"
    )))

    if path == "/" or path == "/index.html" then
        BuildHeaders(stream, 200, "text/html")
        assert(stream:write_body_from_file(assert(io.open("./web/index.html"))))

    elseif path == "/main.js" then
        BuildHeaders(stream, 200, "text/javascript")
        assert(stream:write_body_from_file(assert(io.open("./web/main.js"))))

    elseif path == "/configure" and req_method == "POST" then
        BuildHeaders(stream, 200, "text/plain", true)
        local body = stream:get_body_as_string(0.01)
        print(body)

    elseif path == "/action/reload" and req_method == "POST" then
        BuildHeaders(stream, 200, "text/plain", true)
        local loader = require "loader"
        loader.HotReload()

    else
        BuildHeaders(stream, 404, "text/html")
        assert(stream:write_chunk("Error 404"))
    end

end

local myserver = assert(http_server.listen {
    host = "0.0.0.0";
    port = port;
    onstream = reply;
    onerror = function(myserver, context, op, err, errno) -- luacheck: ignore 212
        local msg = op .. " on " .. tostring(context) .. " failed"
        if err then
            msg = msg .. ": " .. tostring(err)
        end
        assert(io.stderr:write(msg, "\n"))
    end;
})

-- Manually call :listen() so that we are bound before calling :localname()
assert(myserver:listen())
do
    local bound_port = select(3, myserver:localname())
    assert(io.stderr:write(string.format("Now listening on port %d\n", bound_port)))
end

function server:update()
    myserver:step(0.01)
end

function server:close()
    myserver:close()
end

return server
