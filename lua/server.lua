--[[
Start a local HTTP server.
Tweaking can be done on a web browser over the network!
]]

local server = {}

local config_html = ""
local tweak

local port = 3636

local http_server = require "http.server"
local http_headers = require "http.headers"

local Result = function (v, ...)
    if type(v) == "function" then return v(...) end
    return v
end

local BuildHeaders = function (stream, status, content_type, close)
    if close == nil then close = false end

    local res_headers = http_headers.new()
    res_headers:append(":status", tostring(status))
    res_headers:append("content-type", content_type)

    assert(stream:write_headers(res_headers, close))
end

local GetValue = function (var)
    return Result(var.value) or tweak.vars[var.id]
end

local Substitute = function (s, t)
    return (string.gsub(s, "%$(%w+)", t))
end

local BuildConfigItem = function (var)
    if var.type == "range" then
        return Substitute([[<div>
            <label for="$id">$name</label>
            <input type="range" id="$id" name="$id" min="$min" max="$max"
            value="$value" step="$step" class="config"></div>
        ]], {
            id=Result(var.id),
            min=Result(var.min),
            max=Result(var.max),
            name=Result(var.name),
            value=GetValue(var),
            step=Result(var.step) or "any",
        })

    elseif var.type == "options" then
        local s = "<fieldset><legend>"..var.name.."</legend>"
        s = s .. "<div>"
        for i, option in ipairs(assert(var.options)) do
            s = s .. Substitute([[
                <input type="radio" id="$id" name="$name" value="$option" class="config" $checked>
                <label for="$id">$option</label>
            ]], {
                name=var.id,
                option=option,
                id=var.id.."-"..option,
                checked=GetValue(var) == option and "checked" or "",
            })
          
        end
        s = s .. "</div></fieldset>"
        return s

    elseif var.type == "action" then
        return (string.gsub([[<div>
            <button type="button" id="$id" class="config">$name</button>
        ]], "%$(%w+)", var))

    else
        print(strint.format("Unknown twek type `%s`", var.type))
        return "??"
    end
end

local ConfigHtml = function ()
    local items = {}
    for i,v in ipairs(tweak) do
        table.insert(items, BuildConfigItem(v))
    end
    return table.concat(items)
end

local function reply(myserver, stream) -- luacheck: ignore 212
    -- Read in headers
    local req_headers = assert(stream:get_headers())
    local req_method = req_headers:get ":method"

    local path = req_headers:get(":path") or ""
    if false then
        -- Log request to stdout
        assert(io.stdout:write(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s"\n',
        os.date("%d/%b/%Y:%H:%M:%S %z"),
        req_method or "",
        path,
        stream.connection.version,
        req_headers:get("referer") or "-",
        req_headers:get("user-agent") or "-"
        )))
    end

    if path == "/" then
        BuildHeaders(stream, 200, "text/html")
        assert(stream:write_body_from_file(assert(io.open("./web/index.html"))))

    elseif path == "/main.js" then
        BuildHeaders(stream, 200, "text/javascript")
        assert(stream:write_body_from_file(assert(io.open("./web"..path))))

    elseif path == "/style.css" then
        BuildHeaders(stream, 200, "text/css")
        assert(stream:write_body_from_file(assert(io.open("./web"..path))))


    elseif path == "/api/tweak" and req_method == "POST" then
        -- Get data
        local body = stream:get_body_as_string(0.01)

        local id, value = body:match("^([_%w]+)=(.+)$")
        if not id then
            BuildHeaders(stream, 300, "text/plain", true)
            error("could not parse body format")
        end

        assert(tweak[id], "received unknown config var id")
        local number = tonumber(value)
        if number then
            BuildHeaders(stream, 200, "text/plain", true)
            if tweak.vars[id] then
                tweak.vars[id] = number
            end
            if tweak[id].callback then
                tweak[id].callback(number)
            end
        else
            if tweak.vars[id] then
                tweak.vars[id] = value
            end
            if tweak[id].callback then
                tweak[id].callback(value)
            end
        end

    elseif path == "/api/tweaks" and req_method == "GET" then
        BuildHeaders(stream, 200, "text/html")
        local html = ConfigHtml()
        assert(stream:write_chunk(html, true))

    elseif path == "/api/action" and req_method == "POST" then
        BuildHeaders(stream, 200, "text/plain", true)
        local loader = require "loader"
        local id = stream:get_body_as_string(0.01)
        assert(tweak[id], "received unknown action var id")
        local callback = assert(tweak[id].callback, "action missing callback")
        callback()

    elseif path == "/api/update" and req_method == "POST" then
        BuildHeaders(stream, 200, "application/json")
        local s = "{"
        for i = 1, #tweak do
            local value = GetValue(tweak[i])
            if value then
                s = s .. "\""..tweak[i].id.."\": \""..tostring(value).."\" "
                if i < #tweak then s = s .. "," end
            end
        end
        s = s .. "}"
        assert(stream:write_chunk(s, true))

    elseif path == "/action/reload" and req_method == "POST" then
        BuildHeaders(stream, 200, "text/plain", true)
        local loader = require "loader"
        loader.HotReload()

    elseif path == "/api/module" and req_method == "POST" then
        local name = stream:get_body_as_string(0.01)
        local loader = require "loader"
        loader.LoadModule(name)
        BuildHeaders(stream, 200, "text/plain", true)


    else
        BuildHeaders(stream, 404, "text/html")
        assert(stream:write_chunk("Error 404", true))
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

-- Finds ip on linux systems with `ip` command
local FindIp = function ()
    if require("ffi").os == "Linux" then
        return io.popen("ip -i route"):read('a'):match("src ([%d.]+)")
    end
end

local onstart = function ()
    local bound_port = select(3, myserver:localname())
    local ip = FindIp()
    if ip then
        print(string.format("Web interface at http://localhost:%d or http://%s:%d", bound_port, ip, bound_port))
    else
        print(string.format("Web interface at http://localhost:%d %s", bound_port))
    end
end
local started = false

function server:update()
    myserver:step(0.01)
    if not started then
        started = true
        onstart()
    end
end

function server:close()
    myserver:close()
end

function server:MakeConfig(_tweak)
    tweak = _tweak or {}
    tweak.vars = tweak.vars or {}
    for i,v in ipairs(tweak) do
        -- use tweak as hash map too
        tweak[v.id] = v
    end
end

-- Hot reload
if TheServer then TheServer:close() end

TheServer = server

return server
