#ifndef GEOMETRY_DEFS_H
#define GEOMETRY_DEFS_H
#include "common.h"

typedef struct {
    size_t num_vertices;
    const float *vertices;
    size_t num_indices;
    const float *indices;
} Geometry;

extern const Geometry QUAD_GEOMETRY;

#endif // !GEOMETRY_DEFS_H
