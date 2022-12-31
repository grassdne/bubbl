#ifndef COMMON_H
#define COMMON_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>

#define ERROR() strerror(errno)
#define MIN(a,b) (((a) < (b)) ? (a) : (b))
#define STATIC_LEN(arr) (sizeof(arr) / sizeof(arr[0]))

extern int window_width;
extern int window_height;
extern float scale;
extern const float QUAD[8];

#define SCALECONTENT(p) (p * scale)

double get_time(void);

typedef struct {
    float r, g, b;
} Color;

#endif
