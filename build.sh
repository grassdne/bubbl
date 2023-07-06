#!/bin/sh

set -e # Quit on error

DEPS="luajit sdl2 glew"


if $(pkg-config --exists libpng zlib); then
    DEPS+=" libpng zlib"
else
    echo "WARNING: could not find libpng and zlib; screenshots will not work"
fi

CFLAGS="-Wall -Wextra -std=c11 --pedantic -Ideps $(pkg-config --cflags $DEPS)"
CLIBS="$(pkg-config --libs $DEPS) -lm"
CSRC="src/bg.c src/entity_renderer.c src/main.c src/renderer_defs.c src/shaderutil.c"

if [ `uname` = Darwin ]; then
    CLIBS+=" -framework OpenGL -framework IOKit"
else
    # Export symbols for LuaJIT FFI
    CFLAGS+=" -rdynamic"
fi

if [[ $BUBBL_DEV > 0 ]]; then
    CFLAGS+=" -g"
else
    CFLAGS+=" -O3"
fi

set -x # Echo commmand
${CC:=cc} -o bubbl $CSRC $CFLAGS $CLIBS 
