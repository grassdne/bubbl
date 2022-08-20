CC=cc
CFLAGS=-pedantic -Wall -Wextra
CLIBS=-lGL -lGLU -lglfw3 -lX11 -lXrandr -lpthread -lXi -ldl -lXinerama -lXcursor -lm -lGLEW

CMAIN=src/main.c
CSRC=$(CMAIN) src/loader.c src/vector2.c
SRC=$(CSRC) shaders/bubble_quad.vert shaders/bubble.frag
COUT=main

all: main

debug: CFLAGS += -g
debug: main

run: main
	./main

clean:
	rm -f $(COUT)

main: $(SRC)
	$(CC) -o $(COUT) $(CSRC) $(CFLAGS) $(CLIBS)

main.exe: $(SRC)
	gcc.exe -o main.exe $(CSRC) $(CFLAGS) "-LC:\GL\GLFWx86\lib-mingw" -luser32 -lkernel32 "-LC:\GL\GLEWbin\lib\Release\Win32" "-IC:\GL\GLFWx86\include" "-IC:\GL\GLEWbin\include" -lopengl32 -lglu32 -lgdi32 -lglew32 -lmingw32 -lglfw3dll
