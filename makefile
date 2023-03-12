PKGS = luajit sdl2 glew
CFLAGS=-pedantic -Wall -Wextra `pkg-config --cflags $(PKGS)` -Ideps
CLIBS = `pkg-config --libs $(PKGS)` -lm -rdynamic

CMAIN=src/main.c
CSRC=src/bg.c src/entity_renderer.c src/main.c src/renderer_defs.c src/shaderutil.c
EXE=bubbl
CMODULES_OBJ = modules/foo.so
CMODULES_SRC = modules/foo.c

INCLUDE_DIRS_WIN = -IC:\mingw_dev\include
LIBRARY_DIRS_WIN = -LC:\mingw_dev\lib
EXE_WIN = main.exe
CC_WIN = gcc.exe
CLIBS_WIN = -luser32 -lkernel32 -lopengl32 -lglu32 -lgdi32 -lglew32 -lmingw32 -lglfw3dll

CLIBS_MACOS = -framework OpenGL -framework IOKit

all: $(EXE) $(CMODULES_OBJ)

debug: CFLAGS += -g
debug: $(EXE)

release: CFLAGS += -O3
release: $(EXE)

CFLAGS_WIN = $(CFLAGS)

run: CFLAGS += -Werror
run: $(EXE)
	./$(EXE)

clean:
	rm -f $(EXE) $(EXE_WIN) $(CMODULES_OBJ)

compile_commands:
	bear -- $(MAKE) clean all

$(CMODULES_OBJ): $(CMODULES_SRC) src/api.h
	gcc -shared -fPIC $< -o $@


$(EXE): $(CSRC) src/*.h makefile
ifeq ($(OS),Windows_NT)
	$(CC_WIN) $(CSRC) $(INCLUDE_DIRS_WIN) $(LIBRARY_DIRS_WIN) $(CFLAGS_WIN) $(CLIBS_WIN) -o $(EXE_WIN)
else ifeq ($(shell uname),Darwin)
	$(CC) -o $(EXE) $(CSRC) $(CFLAGS) $(CLIBS) $(CLIBS_MACOS)
else
	$(CC) -o $(EXE) $(CSRC) $(CFLAGS) $(CLIBS)
endif

.PHONY: all debug release install clean run
