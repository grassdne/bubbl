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
bool screenshot(Window *window, const char *file_name);
void flush_renderers(void);
void clear_screen(void);
void bg_draw(int texture, void *data, int width, int height);

bool should_quit(void);
Window *create_window(const char *window_name, int width, int height);
void destroy_window(Window *window);
void set_window_title(Window *window, const char *title);
void set_window_size(Window *window, int width, int height);
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

typedef struct gifski gifski;
typedef struct GifskiSettings {
  /**
   * Resize to max this width if non-0.
   */
  uint32_t width;
  /**
   * Resize to max this height if width is non-0. Note that aspect ratio is not preserved.
   */
  uint32_t height;
  /**
   * 1-100, but useful range is 50-100. Recommended to set to 90.
   */
  uint8_t quality;
  /**
   * Lower quality, but faster encode.
   */
  bool fast;
  /**
   * If negative, looping is disabled. The number of times the sequence is repeated. 0 to loop forever.
   */
  int16_t repeat;
} GifskiSettings;

typedef int GifskiError;

gifski *gifski_new(const GifskiSettings *settings);
GifskiError gifski_add_frame_rgba(gifski *handle,
                                  uint32_t frame_number,
                                  uint32_t width,
                                  uint32_t height,
                                  const unsigned char *pixels,
                                  double presentation_timestamp);
GifskiError gifski_finish(gifski *g);
GifskiError gifski_set_file_output(gifski *handle, const char *destination_path);

uint8_t get_screen_pixels(Window *window, uint8_t *pixels);
#endif
