CC = clang
CFLAGS=-pedantic -Wall -Wextra -Wno-dollar-in-identifier-extension
CLIBS = `pkg-config --libs glfw3 glew` -lm -framework OpenGL -framework IOKit

CMAIN=src/main.c
CSRC=src/*.c
EXE=main

INCLUDE_DIRS_WIN = -IC:\mingw_dev\include
LIBRARY_DIRS_WIN = -LC:\mingw_dev\lib
EXE_WIN = main.exe
CC_WIN = gcc.exe
CLIBS_WIN = -luser32 -lkernel32 -lopengl32 -lglu32 -lgdi32 -lglew32 -lmingw32 -lglfw3dll

all: $(EXE)

debug: CFLAGS += -g
debug: $(EXE)

release: CFLAGS += -O3
release: $(EXE)

CFLAGS_WIN = $(CFLAGS)

run: CFLAGS += -Werror
run: $(EXE)
	./$(EXE)

clean:
	rm -f $(EXE) $(EXE_WIN)

main: $(CSRC) src/*.h

ifeq ($(OS),Windows_NT)
	$(CC_WIN) $(CSRC) $(INCLUDE_DIRS_WIN) $(LIBRARY_DIRS_WIN) $(CFLAGS_WIN) $(CLIBS_WIN) -o $(EXE_WIN)
else
	$(CC) -o $(EXE) $(CSRC) $(CFLAGS) $(CLIBS)
endif
