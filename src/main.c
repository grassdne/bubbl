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

#define SCREEN_WIDTH 1600
#define SCREEN_HEIGHT 900

typedef struct {
    BubbleShader bubble;
} Shaders;

static Shaders shaders;

int window_width = SCREEN_WIDTH;
int window_height = SCREEN_HEIGHT;
const float QUAD[] = { 1.0,  1.0, -1.0,  1.0, 1.0, -1.0, -1.0, -1.0 };

static void error_callback(int error, const char* description) {
	(void)error;
	fputs(description, stderr);
}

static void on_mouse_down(GLFWwindow* window, int button, int action, int mods) {
    (void)mods;
    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        double xpos, ypos;
        glfwGetCursorPos(window, &xpos, &ypos);	
        Vector2 mouse = {xpos, window_height - ypos};

        bubbleOnMouseDown(&shaders.bubble, mouse);
    }
}

static void on_window_resize(GLFWwindow *window, int width, int height) {
    (void)window;
    window_width = width;
    window_height = height;
    glViewport(0, 0, width, height);
}

static void frame(GLFWwindow *window, double dt) {
    (void)window;
    glfwPollEvents();
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    bubbleOnDraw(&shaders.bubble, dt);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	(void)scancode; (void)mods;
    if (action == GLFW_RELEASE) {
        switch (key) {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(window, GL_TRUE);
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

    glfwSetMouseButtonCallback(window, on_mouse_down);

	//glfwSwapInterval(100);

    double seconds = glfwGetTime();
	while (!glfwWindowShouldClose(window)) {
        double now = glfwGetTime();
        double dt = now - seconds;
        seconds = now;

        frame(window, dt);
        glfwSwapBuffers(window);
	}

	glfwDestroyWindow(window);
	glfwTerminate();

    return 0;
}

