// Vertex and index buffers for geometry

#include "geometry_defs.h"

static const float quad_vertices[] = {
    1.0,  1.0, 0.0f, // Top right
    -1.0,  1.0, 0.0f, // Top left
    1.0, -1.0, 0.0f, // Bottom right
    -1.0, -1.0, 0.0f, // Bottom left
};

static const unsigned int quad_indices[] = {
    0, 1, 2,
    2, 1, 3,
};

const Geometry QUAD_GEOMETRY = {
    .vertices = quad_vertices,
    .vertices_size = sizeof(quad_vertices),
    .indices = quad_indices,
    .count = sizeof(quad_indices) / sizeof(quad_vertices[0]),
    .draw_mode = GL_TRIANGLES,
};

static const float cube_vertices[] = {
    1.0,  1.0, 1.0f,   // 0: Top right front
    -1.0,  1.0, 1.0f,  // 1: Top left front
    1.0, -1.0, 1.0f,   // 2: Bottom right front
    -1.0, -1.0, 1.0f,  // 3: Bottom left front

    1.0,  1.0, -1.0f,  // 4: Top right back
    -1.0,  1.0, -1.0f, // 5: Top left back
    1.0, -1.0, -1.0f,  // 6: Bottom right back
    -1.0, -1.0, -1.0f, // 7: Bottom left back
};

static const unsigned int cube_indices[] = {
    // Front side
    0, 1, 2,
    2, 1, 3,

    // Back side
    6, 5, 4,
    5, 6, 7,

    // Right side
    0, 2, 4,
    4, 2, 6,

    // Left side
    1, 3, 5,
    5, 3, 7,

    // Top side
    0, 4, 1,
    1, 4, 5,

    // Bottom side
    3, 7, 6,
    6, 3, 2,
};

const Geometry CUBE_GEOMETRY = {
    .vertices = cube_vertices,
    .vertices_size = sizeof(cube_vertices),
    .indices = cube_indices,
    .count = sizeof(cube_indices) / sizeof(cube_indices[0]),
    .draw_mode = GL_TRIANGLES,
};
