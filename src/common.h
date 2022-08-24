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
extern const float QUAD[8];

typedef struct {
    float r, g, b;
} Color;

#endif
