/*
 * The C function headers to call from Lua.
 * see lua/api.lua
*/

#ifndef API_H
#define API_H
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
    float x, y;
} Vector2;

typedef struct {
    float x, y, z;
} Vector3;

typedef struct Matrix {
    float m0, m4, m8, m12;
    float m1, m5, m9, m13;
    float m2, m6, m10, m14;
    float m3, m7, m11, m15;
} Matrix;

typedef struct {
    float r, g, b, a;
} Color;

typedef char GLbyte;

typedef struct  {
    Vector3 pos;
    float rad;
    Color color;
} Bubble;

typedef struct  {
    Vector3 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} TransBubble;

typedef struct {
    uint8_t r, g, b, a;
} Pixel;

// Opaque types
typedef struct {} BgShader;

typedef struct {} Geometry;

typedef struct {
    unsigned int program;
    unsigned int vao; 
    unsigned int ebo;
    const Geometry *geometry;
} Shader;

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
void flush_bubbles(void);
void flush_pops(void);

void render_bubble(Bubble bubble);
void render_test3d(Vector3 position, Color color, float radius);
void render_pop(Vector3 position, Color color, float radius);
void render_trans_bubble(TransBubble bubble);
void render_box(Vector3 position, Color color, float size);

double get_time(void);
bool screenshot(Window *window, const char *file_name);
void flush_renderers(void);
void start_drawing(Window *window);
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

void shader_program_from_source(Shader *shader, const char *id, const char *vertex_source, const char *fragment_source);
void run_shader_program(Shader *shader, size_t num_instances);
void use_shader_program(Shader *shader);
void shader_quad(Shader *sh);

int glGetUniformLocation(unsigned int program, const char *name);
void glUniform4f(int uni, float r, float g, float b, float a);
void glUniform2f(int uni, float x, float y);
void glUniform2f(int uni, float x, float y);
void glUniform1f(int uni, float f);
void glUniform4fv(int uni, int count, Color *values);
void glUniform3fv(int uni, int count, Vector3 *values);
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

enum GifskiError {
  GIFSKI_OK = 0,
  /** one of input arguments was NULL */
  GIFSKI_NULL_ARG,
  /** a one-time function was called twice, or functions were called in wrong order */
  GIFSKI_INVALID_STATE,
  /** internal error related to palette quantization */
  GIFSKI_QUANT,
  /** internal error related to gif composing */
  GIFSKI_GIF,
  /** internal error - unexpectedly aborted */
  GIFSKI_THREAD_LOST,
  /** I/O error: file or directory not found */
  GIFSKI_NOT_FOUND,
  /** I/O error: permission denied */
  GIFSKI_PERMISSION_DENIED,
  /** I/O error: file already exists */
  GIFSKI_ALREADY_EXISTS,
  /** invalid arguments passed to function */
  GIFSKI_INVALID_INPUT,
  /** misc I/O error */
  GIFSKI_TIMED_OUT,
  /** misc I/O error */
  GIFSKI_WRITE_ZERO,
  /** misc I/O error */
  GIFSKI_INTERRUPTED,
  /** misc I/O error */
  GIFSKI_UNEXPECTED_EOF,
  /** progress callback returned 0, writing aborted */
  GIFSKI_ABORTED,
  /** should not happen, file a bug */
  GIFSKI_OTHER,
};

typedef enum GifskiError GifskiError;

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
