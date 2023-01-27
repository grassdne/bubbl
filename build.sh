#!/bin/sh

set -e # Quit on error

DEPS="luajit sdl2 glew"

CFLAGS="-Wall -Wextra -std=c11 --pedantic $(pkg-config --cflags $DEPS)"
CLIBS="$(pkg-config --libs $DEPS)"

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
${CC:=cc} -o bubbles src/all.c $CFLAGS $CLIBS 
