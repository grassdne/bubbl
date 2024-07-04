/* Author: Rustum Zia
 * This is the engine for Bubbl.
 * It creates the window and initialized OpenGL and my renderer(s).
 * It initializes Lua which is where most logic is located.
 * And it interfaces between everybody.
 *
 * Here is how the components of this project generally
 * relate to each other:
 * Web interface -> Lua logic -> C engine -> OpenGL shaders
 */

#define RAYMATH_IMPLEMENTATION
#include "raymath.h"

#define GLAD_GL_IMPLEMENTATION
#include "gl.h"

#include "background_renderer.h"
#include "common.h"
#include "renderer_defs.h"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <png.h>

#define _CRT_SECURE_NO_WARNINGS
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include "SDL_mouse.h"
#include "SDL_video.h"

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>


// We're first rendering to an intermediary color texture which must be done through
// a Frame Buffer Object. This is then blit to the screen.
// I think this is how people normally do things?
// Anyways, we do this for two reasons:
// 1. Post-processing effects (TODO)
// 2. GIF generation doesn't require the screen or need to get
//    ruined when e.g. screen is resized
static GLuint intermediary_framebuffer = 0;
static GLuint intermediary_color_texture = 0;

// How about we just do everything in seconds please and thank you
double get_time(void) { return SDL_GetTicks64() * 0.001; }

float scale;

static void message_callback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar* message, const void* userParam) {
    (void)type;
    (void)id;
    (void)severity;
    (void)userParam;
    (void)source;
    (void)length;
    if (type == GL_DEBUG_TYPE_ERROR_ARB) {
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
    luaL_traceback(L, L, lua_tostring(L, -1), 2);
    error(L, "%s\n", lua_tostring(L, -1));
    return 1;
}

static int run_file(lua_State *L, const char *file) {
    return luaL_loadfile(L, file) || lua_pcall(L, 0, LUA_MULTRET, 1);
}

static void createargtable (lua_State *L, char **argv, int argc) {
  lua_createtable(L, argc-1, 1);
  for (int i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i);
  }
  lua_setglobal(L, "arg");
}

static void allocate_intermediary_color_texture(SDL_Window *window) {
    glBindTexture(GL_TEXTURE_2D, intermediary_color_texture);
    int w, h;
    SDL_GetWindowSize(window, &w, &h);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, 0);
}

static void init_intermediary_framebuffer(SDL_Window *window) {
    glGenFramebuffers(1, &intermediary_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, intermediary_framebuffer);

    glGenTextures(1, &intermediary_color_texture);

    glBindTexture(GL_TEXTURE_2D, intermediary_color_texture);

    allocate_intermediary_color_texture(window);
    int w, h;
    SDL_GetWindowSize(window, &w, &h);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, 0);
    
    // Is this needed?
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, intermediary_color_texture, 0);

    GLenum DrawBuffers[1] = {GL_COLOR_ATTACHMENT0};
    glDrawBuffers(1, DrawBuffers);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        printf("Error: unable to build intermediary_framebuffer\n");
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

static void clear_screen(void) {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

void start_drawing(SDL_Window *window) {
    glBindFramebuffer(GL_FRAMEBUFFER, intermediary_framebuffer);
    int w, h;
    SDL_GetWindowSize(window, &w, &h);
    glViewport(0,0,w,h);
    clear_screen();
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
    int w, h; SDL_GetWindowSize(window, &w, &h);
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
                        .mousebutton.position = (Vector2){ e.button.x, h - e.button.y },
                };
            }
            break;

        case SDL_MOUSEMOTION:
            return (Event) {
                .type = EVENT_MOUSEMOTION,
                .mousemotion.position = (Vector2){ e.button.x, h - e.button.y },
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
                SDL_GL_GetDrawableSize(window, &w, &h);
                glViewport(0, 0, w, h);
                allocate_intermediary_color_texture(window);

                return (Event) {
                    .type = EVENT_RESIZE,
                    .resize.width = w,
                    .resize.height = h,
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

static void vertical_flip_pixels(uint8_t *pixels, int w, int h) {
    int stride = w * 4;
    uint8_t tmp[stride]; // VLA
    for (int i = 0; i < h / 2; ++i) {
        const int row_a = i;
        const int row_b = h - i - 1;
        if (row_a == row_b) break; // memcpy regions must not overlap

        // Swap rows
        uint8_t *ptr_a = &pixels[row_a * stride];
        uint8_t *ptr_b = &pixels[row_b * stride];
        memcpy(tmp, ptr_a, stride);     // First copy a to tmp
        memcpy(ptr_a, ptr_b, stride);   // Then copy b to a
        memcpy(ptr_b, tmp, stride);     // Finally copy tmp to b
    }
}

void get_screen_pixels(SDL_Window *window, uint8_t *pixels) {
    int w, h; SDL_GetWindowSize(window, &w, &h);
    flush_renderers();
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    vertical_flip_pixels(pixels, w, h);
}

void get_framebuffer_pixels(SDL_Window *window, uint8_t *pixels) {
    (void)window;
    int w, h; SDL_GetWindowSize(window, &w, &h);
    flush_renderers();
    glBindTexture(GL_TEXTURE_2D, intermediary_color_texture);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    vertical_flip_pixels(pixels, w, h);
}

bool screenshot(SDL_Window *window, const char *file_name)
{
    int w, h; SDL_GetWindowSize(window, &w, &h);
    const int ncomps = 4;
    const size_t stride = w * ncomps;
    uint8_t *pixeldata = malloc(h * stride);

    /* get_screen_pixels(window, pixeldata); */
    get_framebuffer_pixels(window, pixeldata);

    png_image image = {
        .version = PNG_IMAGE_VERSION,
        .opaque = NULL,
        .width = w,
        .height = h,
        .format = PNG_FORMAT_RGBA,
        .flags = 0,
        .colormap_entries = 0,
    };

    int ok = png_image_write_to_file (&image, file_name, 0,  pixeldata, 0, NULL);

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

    int version = gladLoadGL((GLADloadfunc) SDL_GL_GetProcAddress);
    printf("GL %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));

    if (getenv("USE_VSYNC")) {
        fprintf(stderr, "INFO: Attempting to set VSync\n");
        if (SDL_GL_SetSwapInterval(-1) < 0) {
            fprintf(stderr, "WARNING: Adaptive VSync not supported. Retrying with VSync..\n");
            if (SDL_GL_SetSwapInterval(1) < 0) {
                fprintf(stderr, "WARNING: unable to set VSync: %s\n", SDL_GetError());
            }
        
        }
    }

	//else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
    //    fprintf(stderr, "Shaders not available\n");
    //    exit(1);
	//}

    if (GL_ARB_debug_output) {
        printf("Enabling debug output extension\n");
        // OpenGL 4 extension
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB);
        glDebugMessageCallbackARB(message_callback, NULL);
        glDebugMessageControlARB(/*source*/GL_DONT_CARE,
                              /*type*/GL_DEBUG_TYPE_OTHER_ARB,
                              /* severity */GL_DONT_CARE,
                              0, NULL, false);
    } else {
        printf("Debug output extension not found!\n");
    }
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendEquation(GL_FUNC_ADD);

    init_renderers();
    bg_init();
    init_intermediary_framebuffer(window);
    return window;
}

void destroy_window(SDL_Window *window) 
{
    SDL_GL_DeleteContext(SDL_GL_GetCurrentContext());
    SDL_DestroyWindow(window);
}

void set_window_title(SDL_Window *window, const char *title) {
    SDL_SetWindowTitle(window, title);
}

void set_window_size(SDL_Window *window, int width, int height) {
    SDL_SetWindowSize(window, width, height);
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
    glBindFramebuffer(GL_READ_FRAMEBUFFER, intermediary_framebuffer);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    int w, h;
    SDL_GetWindowSize(window, &w, &h);
    glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    SDL_GL_SwapWindow(window);
}

int main(int argc, char **argv) {
    (void)argc;

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

    if (run_file(L, "lua/init.lua")) {
        error(L, "error loading init.lua:\n%s", lua_tostring(L, -1));
    }

    if (run_file(L, "lua/eventloop.lua")) {
        error(L, lua_tostring(L, -1));
    }

    SDL_Quit();
    lua_close(L);
    return 0;
}
