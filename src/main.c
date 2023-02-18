#include "lua.h"
#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>

#define SDL_MAIN_HANDLED
#include <SDL.h>

#include "luajit.h"
#include <lualib.h>
#include <lauxlib.h>

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <assert.h>

#include "common.h"
#include "renderer_defs.h"
#include "bgshader.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

BgShader bg_shader = {0};

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

static void message_callback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar* message, const void* userParam) {
    (void)type;
    (void)id;
    (void)severity;
    (void)userParam;
    (void)source;
    (void)length;
    if (type == GL_DEBUG_TYPE_ERROR) {
        fprintf(stderr, "OpenGL ERROR: %s\n", message);
        exit(1);
    } else {
        fprintf(stderr, "OpenGL Message: %s\n", message);
    }
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

static void createargtable (lua_State *L, char **argv, int argc) {
  lua_createtable(L, argc-1, 1);
  for (int i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i);
  }
  lua_setglobal(L, "arg");
}


static void call_lua_callback(lua_State *L, int nargs) {
    lua_pcall(L, nargs, 0, 1);
}

static bool try_get_lua_callback(lua_State *L, const char *name) {
    lua_getglobal(L, name);
    if (lua_isfunction(L, -1)) return true;
    lua_pop(L, 1);
    return false;
}

#define CONFIG_FILE_NAME "lua/config.lua"
void reload_config(lua_State *L, SDL_Window *W, bool err) {
    (void)W;
    if (luaL_dofile(L, "lua/config.lua")) {
        fprintf(stderr, "ERROR loading configuration file:\n\t%s\n", lua_tostring(L, -1));
        if (err) exit(1);
    }
}

BgShader* get_bg_shader(void)
{
    return &bg_shader;
}

int get_window_width(void) { return window_width; }
int get_window_height(void) { return window_height; }

static void frame(SDL_Window *W) {
    double now = get_time();
    double dt = now - lasttime;
    lasttime = now;

    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    lua_State *L = SDL_GetWindowData(W, "L");
    if (try_get_lua_callback(L, "OnUpdate")) {
        lua_pushnumber(L, dt);
        call_lua_callback(L, 1);
    }

    flush_renderers();
    SDL_GL_SwapWindow(W);
}

static void on_window_resize(SDL_Window *W) {
    SDL_GL_GetDrawableSize(W, &window_width, &window_height);
    glViewport(0, 0, window_width, window_height);
    lua_State *L = SDL_GetWindowData(W, "L");
    // Currently we set Lua globals and call callback function
    lua_pushinteger(L, window_width);
    lua_setglobal(L, "window_width");
    lua_pushinteger(L, window_height);
    lua_setglobal(L, "window_height");

    if (try_get_lua_callback(L, "OnWindowResize")) {
        lua_pushnumber(L, window_width);
        lua_pushnumber(L, window_height);
        call_lua_callback(L, 2);
    }
}

uint8_t frame_counter = 0;

int main(int argc, char **argv) {
    (void)argc;
    verbose = argv[1] && argv[1][0] == '-' && argv[1][1] == 'v';

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    lua_pushcfunction(L, error_traceback);
    createargtable(L, argv, argc);

    //SDL_SetHint(SDL_HINT_VIDEODRIVER, "x11,wayland");

    srand(time(NULL));
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
        return fprintf(stderr, "error initializing SDL: %s\n", SDL_GetError()), 1;

    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 );
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 3 );
    SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );

    SDL_Window *window = SDL_CreateWindow("bubbl", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_OPENGL);
    if (window == NULL)
        return fprintf(stderr, "error opening window: %s\n", SDL_GetError()), 1;

    lua_pushlightuserdata(L, window);
    lua_setglobal(L, "window");

    lua_pushinteger(L, window_width);
    lua_setglobal(L, "window_width");
    lua_pushinteger(L, window_height);
    lua_setglobal(L, "window_height");

    if (SDL_GL_CreateContext(window) == NULL)
        return fprintf(stderr, "error creating OpenGL context: %s\n", SDL_GetError()), 1;

    SDL_SetWindowData(window, "L", L);

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

    if (false && GL_ARB_debug_output) {
        // OpenGL 4 extension
        glEnable(GL_DEBUG_OUTPUT);
        glDebugMessageCallback(message_callback, NULL);
        glDebugMessageControl(/*source*/GL_DONT_CARE,
                              /*type*/GL_DEBUG_TYPE_OTHER,
                              /* severity */GL_DONT_CARE,
                              0, NULL, false);
    }
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendEquation(GL_FUNC_ADD);

    init_renderers();
    bgInit(&bg_shader);

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
                if (e.key.keysym.sym == SDLK_ESCAPE) {
                    should_quit = true;
                    break;
                }
                else if (e.key.keysym.sym == SDLK_F11) {
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
                else if (e.key.keysym.sym == SDLK_F2) {
                    int ncomps = 4;
                    void *pixeldata = malloc(window_width * window_height * ncomps);
                    glReadPixels(0, 0, window_width, window_height, GL_RGBA, GL_UNSIGNED_BYTE, pixeldata);
                    char fname[] = "frame000.png";
                    sprintf(fname, "frame%03d.png", frame_counter++);
                    int ok = stbi_write_png(fname, window_width, window_height, ncomps, pixeldata, window_width * ncomps);
                    if (! ok) {
                        fprintf(stderr, "unable to write png file\n");
                        return 1;
                    }
                    free(pixeldata);
                }
                else if (e.key.keysym.sym == SDLK_r) {
                    reload_config(L, window, false);
                }
                /* fallthrough */
            case SDL_KEYUP:
                if (try_get_lua_callback(L, "OnKey")) {
                    lua_pushstring(L, SDL_GetKeyName(e.key.keysym.sym));
                    lua_pushboolean(L, e.type == SDL_KEYDOWN);
                    call_lua_callback(L, 2);
                }
                break;

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                if (e.button.button == SDL_BUTTON_LEFT) {
                    const char *name = e.type == SDL_MOUSEBUTTONUP ? "OnMouseUp" : "OnMouseDown";
                    if (try_get_lua_callback(L, name)) {
                        lua_pushnumber(L, e.button.x);
                        lua_pushnumber(L, window_height - e.button.y);
                        call_lua_callback(L, 2);
                    }
                }
                break;

            case SDL_MOUSEMOTION:
                if (try_get_lua_callback(L, "OnMouseMove")) {
                    lua_pushnumber(L, e.motion.x);
                    lua_pushnumber(L, window_height - e.motion.y);
                    call_lua_callback(L, 2);
                }
                break;

            case SDL_MOUSEWHEEL:
                if (try_get_lua_callback(L, "OnMouseWheel")) {
                    lua_pushnumber(L, e.wheel.preciseX);
                    lua_pushnumber(L, e.wheel.preciseY);
                    call_lua_callback(L, 2);
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

