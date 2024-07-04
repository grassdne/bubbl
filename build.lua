#!/bin/env luajit

local user_clib_dirs = os.getenv("BUBBL_CLIB_DIR") or ""
local user_include_dirs = os.getenv("BUBBL_INCLUDE_DIR") or ""
local gif_disabled = os.getenv("BUBBL_NO_GIF")
local png_disabled = os.getenv("BUBBL_NO_PNG")

local Message = function (type, s, ...)
    io.stderr:write(type, ": ", string.format(s, ...), '\n')
end
Warning = function (...) Message("WARNING", ...) end
Error = function (...) Message("ERROR", ...) os.exit(1) end
Info = function (...) Message("INFO", ...) end

Execute = function (...)
    local cmd = table.concat({ ... }, " ")
    print(cmd)
    return os.execute(cmd)
end
Read = function (...)
    local cmd = table.concat({ ... }, " ")
    print(cmd)
    local f = assert(io.popen(cmd))
    local out = f:read("*a"):gsub("\n$", "")
    if not f:close() then Error("running: %s",cmd) end
    return out
end

local has_pkg_config = Execute("pkg-config --atleast-pkgconfig-version 1.0.0")
if not has_pkg_config then
    print("Error: pkg-config not found")
    return
end

local pkgs = "luajit sdl2 gl"

----- LIBPNG -----
local has_png = not png_disabled and Execute("pkg-config --exists libpng zlib")
if has_png then
    pkgs = pkgs.." libpng zlib"
else
    Warning("libpng cannot be installed")
    Warning("PNG creation disabled")
end


----- GIFSKI -----
local has_cargo = Execute("cargo --version")
local use_gifski = not gif_disabled and has_cargo
if not use_gifski
    or not Execute("cargo build --manifest-path=deps/gifski/Cargo.toml --release --lib")
then
    Warning("gifski cannot be installed")
    Warning("GIF creation disabled")
end

----- LUAROCKS -----
local has_luarocks = Execute("luarocks --version")
if has_luarocks then
    local luarocks = "luarocks --lua-version 5.1 --tree deps/lua_modules"
    Execute(luarocks, "build http")
end

----- C -----
local cc = os.getenv("CC") or "cc"
local csrc = "src/main.c src/background_renderer.c src/entity_renderer.c src/renderer_defs.c src/shaderutil.c src/geometry_defs.c"

if not Execute("pkg-config --exists", pkgs) then
    Error("pkg-config could not find one of: %s", pkgs)
end
local pkgflags = Read("pkg-config --cflags", pkgs)
local pkglibs = Read("pkg-config --libs", pkgs)
local clibs = "-lm"
local cflags = "-Wall -Wextra -std=c11 -rdynamic -I deps/ -g"
Execute(cc, "-o bubbl", csrc, user_include_dirs, pkgflags, cflags, user_clib_dirs, pkglibs, clibs)
