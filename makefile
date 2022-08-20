CC=cc
CFLAGS=-pedantic -Wall -Wextra
CLIBS=-lGL -lGLU -lglfw3 -lX11 -lXrandr -lpthread -lXi -ldl -lXinerama -lXcursor -lm -lGLEW

CMAIN=src/main.c
CSRC=$(CMAIN) src/loader.c src/vector2.c
SRC=$(CSRC) shaders/bubble_quad.vert shaders/bubble.frag
EXE=main

INCLUDE_DIRS_WIN = -IC:\mingw_dev\include
LIBRARY_DIRS_WIN = -LC:\mingw_dev\lib
EXE_WIN = main.exe
CC_WIN = gcc.exe
CLIBS_WIN = -luser32 -lkernel32 -lopengl32 -lglu32 -lgdi32 -lglew32 -lmingw32 -lglfw3dll

all: $(EXE)

debug: CFLAGS += -g
debug: $(EXE)

CFLAGS_WIN = $(CFLAGS)

run: $(EXE)
	./main

clean:
	rm -f $(EXE) $(EXE_WIN)

main: $(SRC)
ifeq ($(OS),Windows_NT)
	$(CC_WIN) $(CSRC) $(INCLUDE_DIRS_WIN) $(LIBRARY_DIRS_WIN) $(CFLAGS_WIN) $(CLIBS_WIN) -o $(EXE_WIN)
else
	$(CC) -o $(EXE) $(CSRC) $(CFLAGS) $(CLIBS)
endif
