// Vertex and index buffers for geometry

#include "geometry_defs.h"

static const float quad_vertices[] = {
        1.0,  1.0, 0.0f, // Top right
        -1.0,  1.0, 0.0f, // Top left
        1.0, -1.0, 0.0f, // Bottom right
        -1.0, -1.0, 0.0f, // Bottom left
};

static const float quad_indices[] = {
    0, 1, 2,
    2, 1, 3,
};

const Geometry QUAD_GEOMETRY = (Geometry) {
    .vertices = quad_vertices,
    .num_vertices = sizeof(quad_vertices) / (sizeof(float) * 3),
    .indices = quad_indices,
    .num_indices = sizeof(quad_indices) / (sizeof(float)),
};
