#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

#include "common.h"
#include "vector2.h"
#include "bubbleshader.h"
#include "poppingshader.h"
#include "bgshader.h"


#define SCREEN_WIDTH 1600
#define SCREEN_HEIGHT 900

typedef struct {
    BubbleShader bubble;
    PoppingShader pop;
    BgShader bg;
} Shaders;

// Zero initialize everything!
static Shaders shaders = {0};

static double lasttime;
static bool paused = false;

static int windowed_xpos, windowed_ypos;

int window_width = SCREEN_WIDTH;
int window_height = SCREEN_HEIGHT;
const float QUAD[] = { 1.0,  1.0, -1.0,  1.0, 1.0, -1.0, -1.0, -1.0 };

static void error_callback(int error, const char* description) {
	(void)error;
	fputs(description, stderr);
}

static void on_mouse_down(GLFWwindow* window, int button, int action, int mods) {
    (void)mods;
    if (button == GLFW_MOUSE_BUTTON_LEFT) {
        double xpos, ypos;
        glfwGetCursorPos(window, &xpos, &ypos);	
        Vector2 mouse = {xpos, window_height - ypos};

        if (action == GLFW_PRESS) {
            bubbleOnMouseDown(&shaders.bubble, mouse);
        }
        else if (action == GLFW_RELEASE) {
            bubbleOnMouseUp(&shaders.bubble, mouse);
        }
    }
}

static void on_mouse_move(GLFWwindow* window, double xpos, double ypos) {
    (void)window;
    bubbleOnMouseMove(&shaders.bubble, (Vector2){xpos, window_height - ypos});
}

// Communicate bubble shader -> popping shader
void onRemoveBubble(Bubble *bubble) {
    poppingPop(&shaders.pop, bubble->pos, bubble->color, bubble->rad);
}

static void frame(GLFWwindow *window) {
    (void)window;

    if (paused) {
        glfwSetTime(lasttime);
    }
    else {
        double now = glfwGetTime();
        double dt = now - lasttime;
        lasttime = now;

        glClearColor(1.0, 1.0, 1.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        bgOnDraw(&shaders.bg, dt);
        bubbleOnDraw(&shaders.bubble, dt);
        poppingOnDraw(&shaders.pop, dt);
        glfwSwapBuffers(window);
    }
}

static void on_window_resize(GLFWwindow *window, int width, int height) {
    (void)window;
    window_width = width;
    window_height = height;
    glViewport(0, 0, width, height);
    frame(window);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	(void)scancode; (void)mods;
    if (action == GLFW_RELEASE) {
        switch (key) {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(window, GL_TRUE);
            break;

        case GLFW_KEY_F11: {
            if (glfwGetWindowMonitor(window)) {
                // Fullscreen -> Windowed
                glfwSetWindowMonitor(window, NULL, windowed_xpos, windowed_ypos, SCREEN_WIDTH, SCREEN_HEIGHT, GLFW_DONT_CARE);
            }
            else {
                // Windowed -> Fullscreen
                // Get resolution
                const GLFWvidmode *mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
                glfwGetWindowPos(window, &windowed_xpos, &windowed_ypos);
                glfwSetWindowMonitor(window, glfwGetPrimaryMonitor(), 0, 0, mode->width, mode->height, mode->refreshRate);
            }

            break;
        }
        }
    }
    else if (action == GLFW_PRESS) {
        switch (key) {
        case GLFW_KEY_SPACE:
            paused = !paused;
            break;
        }
        
    }
}

int main(void)
{
    srand(time(NULL));
	glfwSetErrorCallback(error_callback);
	if( !glfwInit()) exit(1);

    glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);

	GLFWwindow* window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bubbles", NULL, NULL);
	if (!window) {
		glfwTerminate();
		exit(1);
	}

	glfwMakeContextCurrent(window);
	glfwSetKeyCallback(window, key_callback);
    glfwSetWindowSizeCallback(window, on_window_resize);

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

	if (glewInit() != GLEW_OK) {
		fprintf(stderr, "GLEW init failed\n");
		exit(1);
	}
	else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
		printf("Shaders not available\n");
		exit(1);
	}

    printf("OpenGL Version: %s\n", glGetString(GL_VERSION));
    printf("MEMORY USAGE\n");
    printf("Bubbles:    %zu b\n", sizeof(shaders.bubble));
    printf("Pop effect: %zu b\n", sizeof(shaders.pop));
    printf("Background: %zu b\n", sizeof(shaders.bg));
    printf("TOTAL: %zu b\n", sizeof(shaders));

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendEquation(GL_FUNC_ADD);
    //glEnable(GL_DEPTH_TEST);
    //glDepthFunc(GL_LESS);
    //glEnable(GL_CULL_FACE);
    
    bubbleInit(&shaders.bubble);
    poppingInit(&shaders.pop);
    bgInit(&shaders.bg, shaders.bubble.bubbles, &shaders.bubble.num_bubbles);

    glfwSetMouseButtonCallback(window, on_mouse_down);
    glfwSetCursorPosCallback(window, on_mouse_move);

	//glfwSwapInterval(100);

    lasttime = glfwGetTime();
	while (!glfwWindowShouldClose(window)) {
        frame(window);
        glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();

    return 0;
}

