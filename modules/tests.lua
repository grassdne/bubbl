Title "Running tests..."

local tests = {}

local overwrite = NextArg() == "overwrite"

local TestScreenshot = function (name, path, func)
    table.insert(tests, {
        name = name,
        path = "tests/"..path,
        call = func,
    })
end

local SlurpFile = function (path)
    local file = io.open(path)
    if file then
        local contents = file:read("*a")
        file:close()
        return contents
    end
end

local SaveToFile = function (path, str)
    local file = assert(io.open(path, "w"))
    file:write(str)
    file:close()
end

------------------------------------------------------

TestScreenshot("canvas solid red", "solidbg", function()
    local canvas = CreateCanvas { { Color.hex "#550000" } }
    canvas:draw()
end)

TestScreenshot("simple shader", "simpleshader", function()
    local SourceLoader = function()
        return [[
        #version 330
        out vec4 outcolor;
        void main() {
            outcolor = vec4(0, 0.25, 0, 1.0);
        }
        ]]
    end

    RunBgShader("simpleshader", SourceLoader, {})
end)

-- TODO: we need to be able to set the time passed to the shader
-- so this can be consistent
--[[
TestScreenshot("simple bubbles", "simplebubble", function()
    local pos = resolution / 2
    RenderSimple(pos, Color.hex("#FF0000"), 200)
end)
-]]

TestScreenshot("simple pop", "simplepop", function()
    local pos = resolution / 2
    RenderPop(pos, Color.hex("#0000FF"), 200)
end)

------------------------------------------------------

print("overwrite="..tostring(overwrite))
print()

local i = 0
Draw = function()
    i = i + 1
    if not tests[i] then return Quit() end
    local path = tests[i].path..".png"
    local contents = SlurpFile(path)
    print("TEST "..tests[i].name)
    tests[i].call()
    local tmpname = os.tmpname()
    if not Screenshot(tmpname) then
        print("\tFailed to take screenshot!")
        return
    end
    local new_contents = assert(SlurpFile(tmpname))
    if not contents then
        print("\tNo previous test image found")
        SaveToFile(path, new_contents)
    elseif contents == new_contents then
        print("\tSUCCESS")
    elseif overwrite then
        print("\tOVERWRITING "..path)
        SaveToFile(path, new_contents)
        os.remove(tests[i].path..".fail.png")
    else
        print("\tFAILURE")
        SaveToFile(tests[i].path..".fail.png", new_contents)
    end
    os.remove(tmpname)
end
