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
#include <assert.h>

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

static bool started = false;

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

static void error(lua_State *L, const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    fprintf(stderr, "\n");
    va_end(argp);
    lua_close(L);
    exit(1);
}

static int error_traceback(lua_State *L) {
    luaL_traceback(L, L, lua_tostring(L, -1), 1);
    error(L, "lua: %s\n", lua_tostring(L, -1));
    return 1;
}

static void call_lua_callback(lua_State *L, int nargs) {
    lua_pcall(L, nargs, 0, 1);
}

static void on_mouse_button(GLFWwindow* W, int button, int action, int mods) {
    (void)mods;
    lua_State *L = glfwGetWindowUserPointer(W);
    if (button == GLFW_MOUSE_BUTTON_LEFT) {
        double xpos, ypos;
        glfwGetCursorPos(W, &xpos, &ypos);	
        Vector2 mouse = window_to_opengl_pos(xpos, ypos);

        if (action == GLFW_PRESS) {
            lua_getglobal(L, "on_mouse_down");
            if (lua_isfunction(L, -1)) {
                lua_pushnumber(L, mouse.x);
                lua_pushnumber(L, mouse.y);
                call_lua_callback(L, 2);
            } else {
                fprintf(stderr, "WARNING: missing `on_mouse_down` Lua global function\n");
            }
            //bubbleOnMouseDown(&shaders.bubble, mouse);
        }
        else if (action == GLFW_RELEASE) {
            lua_getglobal(L, "on_mouse_up");
            if (lua_isfunction(L, -1)) {
                lua_pushnumber(L, mouse.x);
                lua_pushnumber(L, mouse.y);
                call_lua_callback(L, 2);
            } else {
                fprintf(stderr, "WARNING: missing `on_mouse_up` Lua global function\n");
            }
            //bubbleOnMouseUp(&shaders.bubble, mouse);
        }
    }
}

static void on_mouse_move(GLFWwindow* W, double xpos, double ypos) {
    Vector2 pos = window_to_opengl_pos(xpos, ypos);
    lua_State *L = glfwGetWindowUserPointer(W);
    lua_getglobal(L, "on_mouse_move");
    if (lua_isfunction(L, -1)) {
        lua_pushnumber(L, pos.x);
        lua_pushnumber(L, pos.y);
        call_lua_callback(L, 2);
    } else {
        fprintf(stderr, "WARNING: missing `on_mouse_move` Lua global function\n");
    }
    //bubbleOnMouseMove(&shaders.bubble, window_to_opengl_pos(xpos, ypos));
}

#define CONFIG_FILE_NAME "lua/config.lua"
void reload_config(lua_State *L, GLFWwindow *W) {
    if (luaL_dofile(L, "lua/logic.lua") || luaL_dofile(L, "lua/config.lua"))
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

void create_pop(Vector2 pos, Color color, float rad) {
    poppingPop(&shaders.pop, pos, color, rad);
}

int get_bubble_at_point(Vector2 pos) {
    return bubble_at_point(&shaders.bubble, pos);
}

void destroy_bubble(size_t id) {
    shaders.bubble.bubbles[id].alive = false;
}

static void frame(GLFWwindow *W) {
    (void)W;
    double now = glfwGetTime();
    double dt = now - lasttime;
    lasttime = now;

    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    lua_State *L = glfwGetWindowUserPointer(W);
    lua_getglobal(L, "on_update");
    if (!lua_isfunction(L, -1))
        error(L, "expected `on_update` function in Lua config");
    lua_pushnumber(L, dt);
    call_lua_callback(L, 1);

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
    glViewport(0, 0, width, height);
    window_width = width;
    window_height = height;
    lua_State *L = glfwGetWindowUserPointer(W);
    (void)L;
    lua_pushinteger(L, window_width);
    lua_setglobal(L, "window_width");
    lua_pushinteger(L, window_height);
    lua_setglobal(L, "window_height");

    if (started) frame(W);
}

static void key_callback(GLFWwindow* W, int key, int scancode, int action, int mods) {
	(void)scancode; (void)mods;
    lua_State *L = glfwGetWindowUserPointer(W);
    if (action == GLFW_RELEASE) {
        switch (key) {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(W, GL_TRUE);
            break;

        case GLFW_KEY_F11:
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
    else if (action == GLFW_PRESS) {
        switch (key) {
        case GLFW_KEY_SPACE:
            shaders.bubble.paused_movement = !shaders.bubble.paused_movement;
            break;
        }
    }
    lua_getglobal(L, "on_key");
    lua_pushinteger(L, key);
    lua_pushboolean(L, action == GLFW_PRESS);
    call_lua_callback(L, 2);
}

static void on_window_focus(GLFWwindow *W, int focused) {
    lua_State *L = glfwGetWindowUserPointer(W);
    if (focused) {
        reload_config(L, W);
    }
}

int create_bubble(Color color, Vector2 position, Vector2 velocity, int radius)
{
    Bubble bubble = {
        .color = color,
        .pos = position,
        .v = velocity,
        .rad = radius,
        .trans_color = color,
        .trans_starttime = TRANS_STARTTIME_SENTINAL,
        .alive = true,
    };
    int slot = create_open_bubble_slot(&shaders.bubble);
    assert(slot >= 0 && "unable to create bubble");
    shaders.bubble.bubbles[slot] = bubble;
    return slot;
}
Bubble *get_bubble(size_t id)
{
    if (id < shaders.bubble.num_bubbles+1) {
        Bubble *bubble = &shaders.bubble.bubbles[id];
        if (bubble->alive) {
            return bubble;
        }
    }
    return NULL;
}

int main(int argc, char **argv) {
    (void)argc;
    verbose = argv[1] && argv[1][0] == '-' && argv[1][1] == 'v';

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    lua_pushcfunction(L, error_traceback);

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

    {
        int w, h;
        glfwGetFramebufferSize(W, &w, &h);
        on_framebuffer_resize(W, w, h);
    }

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

    glfwSetMouseButtonCallback(W, on_mouse_button);
    glfwSetCursorPosCallback(W, on_mouse_move);
    glfwSetWindowFocusCallback(W, on_window_focus);

    if (luaL_dofile(L, "lua/init.lua")) {
        error(L, "error loading init.lua:\n%s", lua_tostring(L, -1));
    }
    reload_config(L, W);

    started = true;
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

