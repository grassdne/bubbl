#include "SDL_mouse.h"
#include "SDL_video.h"
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
#include "bg.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define SCREEN_WIDTH 1600
#define SCREEN_HEIGHT 900

bool verbose;
#define VPRINTF(...) if (verbose) printf(__VA_ARGS__)

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


#define CONFIG_FILE_NAME "lua/config.lua"
void reload_config(lua_State *L, bool err) {
    if (luaL_dofile(L, "lua/config.lua")) {
        fprintf(stderr, "ERROR loading configuration file:\n\t%s\n", lua_tostring(L, -1));
        if (err) exit(1);
    }
}

int get_window_width(void) { return window_width; }
int get_window_height(void) { return window_height; }

void clear_screen(void) {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

bool quit = false;
bool should_quit(void) {
    return quit;
}

bool is_fullscreen = false;

typedef enum {
    EVENT_NONE=0,
    EVENT_KEY, EVENT_MOUSEBUTTON,
    EVENT_MOUSEMOTION, EVENT_MOUSEWHEEL,
    EVENT_RESIZE,
} EventType;

typedef struct {
    EventType type;
    union {
        struct {
            const char *name;
            bool is_down;
        } key;
        struct {
            Vector2 position;
            bool is_down;
        } mousebutton;
        struct {
            Vector2 position;
        } mousemotion;
        struct {
            Vector2 scroll;
        } mousewheel;
        struct {
            int width, height;
        } resize;
    };
} Event;

// Handles and/or return event
Event poll_event(SDL_Window *window)
{
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        switch (e.type) {
        case SDL_QUIT:
            quit = true;
            break;
        case SDL_KEYDOWN:
            if (e.key.keysym.sym == SDLK_ESCAPE) {
                quit = true;
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
                break;
            }
            /* fallthrough */
        case SDL_KEYUP:
            return (Event) {
                .type = EVENT_KEY,
                .key.name = SDL_GetKeyName(e.key.keysym.sym),
                .key.is_down = e.type == SDL_KEYDOWN,
            };
            break;

        case SDL_MOUSEBUTTONDOWN:
        case SDL_MOUSEBUTTONUP:
            if (e.button.button == SDL_BUTTON_LEFT) {
                return (Event) {
                    .type = EVENT_MOUSEBUTTON,
                        .mousebutton.is_down = e.type == SDL_MOUSEBUTTONDOWN,
                        .mousebutton.position = (Vector2){ e.button.x, window_height - e.button.y },
                };
            }
            break;

        case SDL_MOUSEMOTION:
            return (Event) {
                .type = EVENT_MOUSEMOTION,
                .mousemotion.position = (Vector2){ e.button.x, window_height - e.button.y },
            };
            break;

        case SDL_MOUSEWHEEL:
            return (Event) {
                .type = EVENT_MOUSEWHEEL,
                .mousewheel.scroll = (Vector2){ e.wheel.preciseX, e.wheel.preciseY },
            };
            break;

        case SDL_WINDOWEVENT:
            if (e.window.event == SDL_WINDOWEVENT_RESIZED) {
                SDL_GL_GetDrawableSize(window, &window_width, &window_height);
                glViewport(0, 0, window_width, window_height);
                return (Event) {
                    .type = EVENT_RESIZE,
                    .resize.width = window_width,
                    .resize.height = window_height,
                };
            }
            break;
        }
    }
    return (Event){ .type = EVENT_NONE };
}
void process_events(SDL_Window *window) {
    (void)window;
    assert(false && "process_events unused");
}

bool screenshot(const char *file_name)
{
    flush_renderers();
    const int ncomps = 4;
    void *pixeldata = malloc(window_width * window_height * ncomps);
    glReadPixels(0, 0, window_width, window_height, GL_RGBA, GL_UNSIGNED_BYTE, pixeldata);
    int ok = stbi_write_png(file_name, window_width, window_height, ncomps, pixeldata, window_width * ncomps);
    if (!ok) return false;
    free(pixeldata);
    return true;
}

SDL_Window *create_window(const char *window_name, int width, int height)
{
    SDL_Window *window = SDL_CreateWindow(window_name, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_OPENGL);
    if (window == NULL) {
        fprintf(stderr, "error opening window: %s\n", SDL_GetError());
        return NULL;
    }
    SDL_GLContext *context = SDL_GL_CreateContext(window);
    if (context == NULL) {
        fprintf(stderr, "error creating OpenGL context: %s\n", SDL_GetError());
        return NULL;
    }
    return window;
}

void destroy_window(SDL_Window *window) 
{
    SDL_DestroyWindow(window);
}

void set_window_title(SDL_Window *window, const char *title) {
    SDL_SetWindowTitle(window, title);
}

Vector2 get_mouse_position(SDL_Window *window)
{
    int height, x, y;
    (void)SDL_GetWindowSize(window, NULL, &height);
    (void)SDL_GetMouseState(&x, &y);
    return (Vector2){ x, height - y };
}

void update_screen(SDL_Window *window)
{
    SDL_GL_SwapWindow(window);
}

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

    if (luaL_dofile(L, "lua/init.lua")) {
        error(L, "error loading init.lua:\n%s", lua_tostring(L, -1));
    }

    GLenum err = glewInit();
	if (err) {
        fprintf(stderr, "GLEW error: %s\n", glewGetErrorString(err));
    }

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

    if (GL_ARB_debug_output) {
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
    bg_init();

    reload_config(L, true);

    if (luaL_dofile(L, "lua/eventloop.lua")) {
        error(L, "Error: %s", lua_tostring(L, -1));
    }

    SDL_Quit();
    lua_close(L);
    return 0;
}
