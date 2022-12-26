#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>

#include "luajit.h"
#include <lualib.h>
#include <lauxlib.h>

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

bool verbose;
#define VPRINTF(...) if (verbose) printf(__VA_ARGS__)

typedef struct {
    BubbleShader bubble;
    PoppingShader pop;
    BgShader bg;
} Shaders;

// Zero initialize everything!
static Shaders shaders = {0};

static double lasttime;

static int windowed_xpos, windowed_ypos;

int window_width = SCREEN_WIDTH;
int window_height = SCREEN_HEIGHT;
float scale;
const float QUAD[] = { 1.0,  1.0, -1.0,  1.0, 1.0, -1.0, -1.0, -1.0 };

static void error_callback(int error, const char* description) {
	(void)error;
	fputs(description, stderr);
}

static Vector2 window_to_opengl_pos(double xpos, double ypos) {
    return (Vector2){xpos*scale, window_height - ypos*scale};
}

static void on_mouse_down(GLFWwindow* W, int button, int action, int mods) {
    (void)mods;
    if (button == GLFW_MOUSE_BUTTON_LEFT) {
        double xpos, ypos;
        glfwGetCursorPos(W, &xpos, &ypos);	
        Vector2 mouse = window_to_opengl_pos(xpos, ypos);

        if (action == GLFW_PRESS) {
            bubbleOnMouseDown(&shaders.bubble, mouse);
        }
        else if (action == GLFW_RELEASE) {
            bubbleOnMouseUp(&shaders.bubble, mouse);
        }
    }
}

static void on_mouse_move(GLFWwindow* W, double xpos, double ypos) {
    (void)W;
    bubbleOnMouseMove(&shaders.bubble, window_to_opengl_pos(xpos, ypos));
}

void error(lua_State *L, const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    fprintf(stderr, "\n");
    va_end(argp);
    lua_close(L);
    exit(EXIT_FAILURE);
}

#define CONFIG_FILE_NAME "config.lua"
void reload_config(lua_State *L, GLFWwindow *W) {
    if (luaL_dofile(L, "logic.lua") || luaL_dofile(L, "config.lua"))
        fprintf(stderr, "ERROR loading configuration file:\n\t%s\n", lua_tostring(L, -1));

    lua_getglobal(L, "title");
    if (!lua_isstring(L, -1)) {
        fprintf(stderr, "expected `title` string in Lua config\n");
    } else {
        glfwSetWindowTitle(W, lua_tostring(L, -1));
    }
}
// Communicate bubble shader -> popping shader
void onRemoveBubble(Bubble *bubble) {
    poppingPop(&shaders.pop, bubble->pos, bubble->color, bubble->rad);
}

static void frame(GLFWwindow *W) {
    (void)W;
    double now = glfwGetTime();
    double dt = now - lasttime;
    lasttime = now;

    lua_State *L = glfwGetWindowUserPointer(W);
    lua_getglobal(L, "on_update");
    if (!lua_isfunction(L, -1))
        error(L, "expected `OnUpdate` function in Lua config");
    lua_pushnumber(L, dt);
    lua_call(L, 1, 0);

    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    bgOnDraw(&shaders.bg, dt);
    bubbleOnDraw(&shaders.bubble, dt);
    poppingOnDraw(&shaders.pop, dt);

    glfwSwapBuffers(W);
    //printf("FPS: %f\n", 1.0 / (glfwGetTime() - now));
}

static void on_content_rescale(GLFWwindow *W, float xs, float ys) {
    (void)W;
    VPRINTF("xscale=%f :: yscale=%f\n", xs, ys);
    if (xs != ys) {
        printf("Error: display s is x%f on the x-axis but x%f on the y axis\n", xs, ys);
    }
    scale = xs;
}

static void on_framebuffer_resize(GLFWwindow *W, int width, int height) {
    (void)W;
    glViewport(0, 0, width, height);
    window_width = width;
    window_height = height;
    frame(W);
}

static void key_callback(GLFWwindow* W, int key, int scancode, int action, int mods) {
	(void)scancode; (void)mods;
    if (action == GLFW_RELEASE) {
        switch (key) {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(W, GL_TRUE);
            break;

        case GLFW_KEY_F11: {
            if (glfwGetWindowMonitor(W)) {
                // Fullscreen -> Windowed
                glfwSetWindowMonitor(W, NULL, windowed_xpos, windowed_ypos, SCREEN_WIDTH, SCREEN_HEIGHT, GLFW_DONT_CARE);
            }
            else {
                // Windowed -> Fullscreen
                // Get resolution
                const GLFWvidmode *mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
                glfwGetWindowPos(W, &windowed_xpos, &windowed_ypos);
                glfwSetWindowMonitor(W, glfwGetPrimaryMonitor(), 0, 0, mode->width, mode->height, mode->refreshRate);
            }

            break;
        }
        }
    }
    else if (action == GLFW_PRESS) {
        switch (key) {
        case GLFW_KEY_SPACE:
            shaders.bubble.paused_movement = !shaders.bubble.paused_movement;
            break;
        }
        
    }
}

static double l_get_number_field(lua_State *L, const char *key) {
    lua_pushstring(L, key);
    lua_gettable(L, -2);
    if (!lua_isnumber(L, -1))
        luaL_error(L, "expected key `%s` in table", key);
    double num = lua_tonumber(L, -1);
    lua_pop(L, 1);
    return num;
}
static int l_create_bubble(lua_State *L) {
    if (!lua_istable(L, -1))
        error(L, "expected valid `color` table argument");

    double red = l_get_number_field(L, "r");
    double green = l_get_number_field(L, "g");
    double blue = l_get_number_field(L, "b");
    printf("red=%f, green=%f, blue=%f\n", red, green, blue);
    return 0;
}

static void on_window_focus(GLFWwindow *W, int focused) {
    lua_State *L = glfwGetWindowUserPointer(W);
    if (focused) {
        reload_config(L, W);
    }
}

int main(int argc, char **argv) {
    (void)argc;
    verbose = argv[1] && argv[1][0] == '-' && argv[1][1] == 'v';

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    lua_pushcfunction(L, l_create_bubble);
    lua_setglobal(L, "create_bubble");

    srand(time(NULL));
	glfwSetErrorCallback(error_callback);
	if( !glfwInit()) exit(1);

    glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

	GLFWwindow* W = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bubbles", NULL, NULL);
	if (!W) {
		glfwTerminate();
		exit(1);
	}

	glfwMakeContextCurrent(W);
	glfwSetKeyCallback(W, key_callback);
    glfwSetFramebufferSizeCallback(W, &on_framebuffer_resize);
    glfwSetWindowUserPointer(W, L);

    glfwGetFramebufferSize(W, &window_width, &window_height);
    glViewport(0, 0, window_width, window_height);

    float xscale, yscale;
    glfwGetWindowContentScale(W, &xscale, &yscale);
    // initial scale
    on_content_rescale(W, xscale, yscale);
    glfwSetWindowContentScaleCallback(W, on_content_rescale);

	if (glewInit() != GLEW_OK) {
		fprintf(stderr, "GLEW init failed\n");
		exit(1);
	}
	//else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
    //    fprintf(stderr, "Shaders not available\n");
    //    exit(1);
	//}

    VPRINTF("OpenGL Version: %s\n", glGetString(GL_VERSION));
    VPRINTF("MEMORY USAGE\n");
    VPRINTF("Bubbles:    %lu b\n", (unsigned long)sizeof(shaders.bubble));
    VPRINTF("Pop effect: %lu b\n", (unsigned long)sizeof(shaders.pop));
    VPRINTF("Background: %lu b\n", (unsigned long)sizeof(shaders.bg));
    VPRINTF("TOTAL: %lu b\n", (unsigned long)sizeof(shaders));

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendEquation(GL_FUNC_ADD);
    //glEnable(GL_DEPTH_TEST);
    //glDepthFunc(GL_LESS);
    //glEnable(GL_CULL_FACE);
    
    bubbleInit(&shaders.bubble);
    poppingInit(&shaders.pop);
    bgInit(&shaders.bg, shaders.bubble.bubbles, &shaders.bubble.num_bubbles);

    glfwSetMouseButtonCallback(W, on_mouse_down);
    glfwSetCursorPosCallback(W, on_mouse_move);
    glfwSetWindowFocusCallback(W, on_window_focus);

    if (luaL_dofile(L, "init.lua")) {
        error(L, "error loading init.lua: %s", lua_tostring(L, -1));
    }
    reload_config(L, W);

    lasttime = glfwGetTime();
	while (!glfwWindowShouldClose(W)) {
        frame(W);
        glfwPollEvents();
	}

	glfwDestroyWindow(W);
	glfwTerminate();

    lua_close(L);
    return 0;
}

