#ifndef COMMON_H
#define COMMON_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>

#define ERROR() strerror(errno)
#define MIN(a,b) (((a) < (b)) ? (a) : (b))
#define STATIC_LEN(arr) (sizeof(arr) / sizeof(arr[0]))

extern float scale;

extern int drawing_width, drawing_height;

#define SCALECONTENT(p) (p * scale)

double get_time(void);

typedef struct {
    float r, g, b, a;
} Color;
typedef struct {
    uint8_t r, g, b, a;
} Pixel;

// Now using raymath
//typedef struct { float x, y; } Vector2;

#endif
