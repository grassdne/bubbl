#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

#include "common.h"
#include "loader.h"
#include "vector2.h"
#include "bubbleshader.h"
#include "poppingshader.h"


#define SCREEN_WIDTH 1600
#define SCREEN_HEIGHT 900

typedef struct {
    BubbleShader bubble;
    PoppingShader pop;
} Shaders;

// Zero initialize everything!
static Shaders shaders = {0};

static double lasttime;
static bool paused = false;

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

static void on_window_resize(GLFWwindow *window, int width, int height) {
    (void)window;
    window_width = width;
    window_height = height;
    glViewport(0, 0, width, height);
}

static void frame(GLFWwindow *window) {
    (void)window;

    glfwPollEvents();
    if (paused) {
        glfwSetTime(lasttime);
    }
    else {
        double now = glfwGetTime();
        double dt = now - lasttime;
        lasttime = now;

        glClearColor(1.0, 1.0, 1.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        poppingOnDraw(&shaders.pop, dt);
        bubbleOnDraw(&shaders.bubble, dt);
        glfwSwapBuffers(window);
    }
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
                glfwSetWindowMonitor(window, NULL, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, GLFW_DONT_CARE);
            }
            else {
                // Windowed -> Fullscreen
                // Get resolution
                const GLFWvidmode *mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
                glfwSetWindowMonitor(window, glfwGetPrimaryMonitor(), 0, 0, mode->width, mode->height, GLFW_DONT_CARE);
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

	GLFWwindow* window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bubbles", NULL, NULL);
	if (!window) {
		glfwTerminate();
		exit(1);
	}

	glfwMakeContextCurrent(window);
	glfwSetKeyCallback(window, key_callback);
    glfwSetWindowSizeCallback(window, on_window_resize);

	if (glewInit() != GLEW_OK) {
		printf("GLEW init failed\n");
		abort();
	}
	else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
		printf("Shaders not available\n");
		abort();
	}

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    printf("OpenGL Version: %s\n", glGetString(GL_VERSION));

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    bubbleInit(&shaders.bubble);
    poppingInit(&shaders.pop);

    glfwSetMouseButtonCallback(window, on_mouse_down);
    glfwSetCursorPosCallback(window, on_mouse_move);

	//glfwSwapInterval(100);

    lasttime = glfwGetTime();
	while (!glfwWindowShouldClose(window)) {

        frame(window);
	}

	glfwDestroyWindow(window);
	glfwTerminate();

    return 0;
}

