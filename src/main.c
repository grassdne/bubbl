#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>

#define SDL_MAIN_HANDLED
#include <SDL.h>

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

static double lasttime;

static bool started = false;

// How about we just do everything in seconds please and thank you
double get_time(void) { return SDL_GetTicks64() * 0.001; }

//static int windowed_xpos, windowed_ypos;

int window_width = SCREEN_WIDTH;
int window_height = SCREEN_HEIGHT;
float scale;
const float QUAD[] = { 1.0,  1.0, -1.0,  1.0, 1.0, -1.0, -1.0, -1.0 };

#if 0
static void error_callback(int error, const char* description) {
	(void)error;
	fputs(description, stderr);
}

static Vector2 window_to_opengl_pos(double xpos, double ypos) {
    return (Vector2){xpos*scale, window_height - ypos*scale};
}
#endif

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

#if 0
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
        }
        else if (action == GLFW_RELEASE) {
            printf ("mouse released!\n");
            lua_getglobal(L, "on_mouse_up");
            if (lua_isfunction(L, -1)) {
                lua_pushnumber(L, mouse.x);
                lua_pushnumber(L, mouse.y);
                call_lua_callback(L, 2);
            } else {
                fprintf(stderr, "WARNING: missing `on_mouse_up` Lua global function\n");
            }
        }
    }
}
#endif

#if 0
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
}
#endif

#define CONFIG_FILE_NAME "lua/config.lua"
void reload_config(lua_State *L, SDL_Window *W, bool err) {
    if (luaL_dofile(L, "lua/config.lua")) {
        fprintf(stderr, "ERROR loading configuration file:\n\t%s\n", lua_tostring(L, -1));
        if (err) exit(1);
    }

    lua_getglobal(L, "title");
    if (!lua_isstring(L, -1)) {
        fprintf(stderr, "expected `title` string in Lua config\n");
    } else {
        SDL_SetWindowTitle(W, lua_tostring(L, -1));
    }
}

BubbleShader* create_bubble_shader(void) {
    BubbleShader *sh = calloc(sizeof(BubbleShader), 1);
    bubbleInit(sh);
    return sh;
}
PoppingShader* create_pop_shader(void) {
    PoppingShader *sh = calloc(sizeof(PoppingShader), 1);
    poppingInit(sh);
    return sh;
}
BgShader* create_bg_shader(BubbleShader *bubble_shader)
{
    BgShader *sh = calloc(sizeof(BgShader), 1);
    bgInit(sh, bubble_shader->bubbles, &bubble_shader->num_bubbles);
    return sh;
}

static void frame(SDL_Window *W) {
    double now = get_time();
    double dt = now - lasttime;
    lasttime = now;

    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    lua_State *L = SDL_GetWindowData(W, "L");
    lua_getglobal(L, "on_update");
    if (!lua_isfunction(L, -1))
        error(L, "expected `on_update` function in Lua config");
    lua_pushnumber(L, dt);
    call_lua_callback(L, 1);

    SDL_GL_SwapWindow(W);
}

#if 0
static void on_content_rescale(GLFWwindow *W, float xs, float ys) {
    (void)W;
    VPRINTF("xscale=%f :: yscale=%f\n", xs, ys);
    if (xs != ys) {
        printf("Error: display s is x%f on the x-axis but x%f on the y axis\n", xs, ys);
    }
    scale = xs;
}
#endif

static void on_window_resize(SDL_Window *W) {
    SDL_GL_GetDrawableSize(W, &window_width, &window_height);
    glViewport(0, 0, window_width, window_height);
    lua_State *L = SDL_GetWindowData(W, "L");
    lua_pushinteger(L, window_width);
    lua_setglobal(L, "window_width");
    lua_pushinteger(L, window_height);
    lua_setglobal(L, "window_height");
}

#if 0
static void on_window_focus(GLFWwindow *W, int focused) {
    lua_State *L = glfwGetWindowUserPointer(W);
    if (focused) {
        reload_config(L, W, false);
    }
}
#endif

int main(int argc, char **argv) {
    (void)argc;
    verbose = argv[1] && argv[1][0] == '-' && argv[1][1] == 'v';

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    lua_pushcfunction(L, error_traceback);

    srand(time(NULL));
	//glfwSetErrorCallback(error_callback);
    //if( !glfwInit()) exit(1);
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
        return fprintf(stderr, "error initializing SDL: %s\n", SDL_GetError()), 1;

    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 );
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 3 );
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );

    SDL_Window *window = SDL_CreateWindow("bubbl", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_OPENGL);
    if (window == NULL)
        return fprintf(stderr, "error opening window: %s\n", SDL_GetError()), 1;

    lua_pushinteger(L, window_width);
    lua_setglobal(L, "window_width");
    lua_pushinteger(L, window_height);
    lua_setglobal(L, "window_height");

    //glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);
    //glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    //glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    //glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    //glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

	//GLFWwindow* W = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bubbles", NULL, NULL);
    
    if (SDL_GL_CreateContext(window) == NULL)
        return fprintf(stderr, "error creating OpenGL context: %s\n", SDL_GetError()), 1;

	//glfwMakeContextCurrent(W);
	//glfwSetKeyCallback(W, key_callback);
    //glfwSetFramebufferSizeCallback(W, &on_framebuffer_resize);
    //glfwSetWindowUserPointer(W, L);

    SDL_SetWindowData(window, "L", L);
    //{
    //    int w, h;
    //    glfwGetFramebufferSize(W, &w, &h);
    //    on_framebuffer_resize(W, w, h);
    //}

    //float xscale, yscale;
    //glfwGetWindowContentScale(W, &xscale, &yscale);
    // initial scale
    //on_content_rescale(W, xscale, yscale);
    //glfwSetWindowContentScaleCallback(W, on_content_rescale);

    GLenum err = glewInit();
	if (err)
		return fprintf(stderr, "error initializing GLEW: %s\n", glewGetErrorString(err)), 1;

    if (SDL_GL_SetSwapInterval(-1) < 0) {
        VPRINTF("Adaptive VSync not supported. Retrying with VSync..");
        if (SDL_GL_SetSwapInterval(1) < 0) {
            return fprintf(stderr, "unable to set VSync: %s\n", SDL_GetError()), 1;
        }

    }
	//else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
    //    fprintf(stderr, "Shaders not available\n");
    //    exit(1);
	//}

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendEquation(GL_FUNC_ADD);
    //glEnable(GL_DEPTH_TEST);
    //glDepthFunc(GL_LESS);
    //glEnable(GL_CULL_FACE);

    //glfwSetMouseButtonCallback(W, on_mouse_button);
    //glfwSetCursorPosCallback(W, on_mouse_move);
    //glfwSetWindowFocusCallback(W, on_window_focus);

    if (luaL_dofile(L, "lua/init.lua")) {
        error(L, "error loading init.lua:\n%s", lua_tostring(L, -1));
    }
    reload_config(L, window, true);

    started = true;
    lasttime = get_time();
    bool is_fullscreen = false;
    bool should_quit = false;
	while (!should_quit) {
        frame(window);
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            switch (e.type) {
            case SDL_QUIT:
                should_quit = true;
                break;
            case SDL_KEYDOWN:
                // TODO: fullscreen
                if (e.key.keysym.sym == SDLK_ESCAPE) {
                    should_quit = true;
                    break;
                }
                else if (e.key.keysym.sym == SDLK_F11) {
                    printf("Hello, World!\n");
                    if (is_fullscreen) {
                        is_fullscreen = false;
                        SDL_SetWindowFullscreen(window, 0);
                        SDL_SetWindowSize(window, SCREEN_WIDTH, SCREEN_HEIGHT);
                    }
                    else {
                        is_fullscreen = true;
                        SDL_SetWindowFullscreen(window, SDL_WINDOW_FULLSCREEN);
                    }
                    on_window_resize(window);
                    break;
                }
                /* fallthrough */
            case SDL_KEYUP:
                lua_getglobal(L, "on_key");
                lua_pushstring(L, SDL_GetKeyName(e.key.keysym.sym));
                lua_pushboolean(L, e.type == SDL_KEYDOWN);
                call_lua_callback(L, 2);
                break;

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                if (e.button.button == SDL_BUTTON_LEFT) {
                    const char *name = e.type == SDL_MOUSEBUTTONUP ? "on_mouse_up" : "on_mouse_down";
                    lua_getglobal(L, name);
                    if (lua_isfunction(L, -1)) {
                        lua_pushnumber(L, e.button.x);
                        lua_pushnumber(L, window_height - e.button.y);
                        call_lua_callback(L, 2);
                    } else {
                        fprintf(stderr, "WARNING: missing `%s` Lua global function\n", name);
                    }
                }
                break;

            case SDL_MOUSEMOTION:
                lua_getglobal(L, "on_mouse_move");
                if (lua_isfunction(L, -1)) {
                    lua_pushnumber(L, e.motion.x);
                    lua_pushnumber(L, window_height - e.motion.y);
                    call_lua_callback(L, 2);
                } else {
                    fprintf(stderr, "WARNING: missing `on_mouse_move` Lua global function\n");
                }
                break;

            case SDL_WINDOWEVENT:
                if (e.window.event == SDL_WINDOWEVENT_RESIZED) {
                    on_window_resize(window);
                }
                break;
            }
        }
	}

    SDL_DestroyWindow(window);
    SDL_Quit();
    lua_close(L);
    return 0;
}

