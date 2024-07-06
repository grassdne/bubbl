#ifndef GEOMETRY_DEFS_H
#define GEOMETRY_DEFS_H
#include "common.h"
#include "gl.h"

typedef struct {
    const GLfloat *vertices; /* Vertices to put in VBO */
    size_t vertices_size; /* Byte size of vertices */
    const GLuint *indices; /* Indices to toss into EBO */
    size_t count; /* Number of indices which is vertex count to pass into glDrawElements */
    GLenum draw_mode; /* GL_TRIANGLES, GL_TRIANGESTRIP, GL_POINTS, etc */
} Geometry;

extern const Geometry QUAD_GEOMETRY;
extern const Geometry CUBE_GEOMETRY;

#endif // !GEOMETRY_DEFS_H
