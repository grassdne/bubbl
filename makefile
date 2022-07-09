CC=cc
CFLAGS=-pedantic -Wall -Wextra
CLIBS=-lGL -lGLU -lglfw3 -lX11 -lXxf86vm -lXrandr -lpthread -lXi -ldl -lXinerama -lXcursor -lm -lGLEW

CMAIN=src/main.c
CSRC=src/*.c src/*.h
SRC=$(CSRC) src/vertex.glsl src/fragment.glsl
COUT="main"

main: $(SRC)
	$(CC) -o $(COUT) $(CSRC) $(CFLAGS) $(CLIBS)

debug: main $(SRC)
	$(CC) -o $(COUT) $(CSRC) $(CFLAGS) -g $(CLIBS)


