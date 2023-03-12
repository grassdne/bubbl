#ifndef API_H
#define API_H
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
    float x, y;
} Vector2;

typedef struct {
    float r, g, b, a;
} Color;

typedef char GLbyte;

typedef struct  {
    Vector2 pos;
    float rad;
    Color color;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} Bubble;

typedef struct {
    uint8_t r, g, b, a;
} Pixel;

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
    float age;
} Particle;

// Opaque types
typedef struct {} BgShader;

typedef struct { unsigned int program; unsigned int vao; } Shader;

typedef struct Window Window;

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

BgShader* get_bg_shader(void);

void free(void *p);
void render_bubble(Bubble bubble);
void flush_bubbles(void);
void flush_pops(void);
void render_pop(Particle particle);
double get_time(void);
bool screenshot(const char *file_name);
void flush_renderers(void);
void clear_screen(void);
void bg_draw(int texture, void *data, int width, int height);

bool should_quit(void);
Window *create_window(const char *window_name, int width, int height);
void destroy_window(Window *window);
void set_window_title(Window *window, const char *title);
void SDL_GL_SwapWindow(Window *window);

Event poll_event(Window *window);
void update_screen(Window *window);
Vector2 get_mouse_position(Window *window);

void create_shader_program(Shader *shader, const char *id, const char *vertex_source, const char *fragment_source);
void run_shader_program(Shader *shader);
void use_shader_program(Shader *shader);
int glGetUniformLocation(unsigned int program, const char *name);
void glUniform4f(int uni, float r, float g, float b, float a);
void glUniform2f(int uni, float x, float y);
void glUniform1f(int uni, float f);
void glUniform4fv(int uni, int count, Color *values);
void glUniform2fv(int uni, int count, Vector2 *values);
int bg_create_texture(void *data, int width, int height);

void on_update(double dt);
#endif
