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

#endif
