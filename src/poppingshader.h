#ifndef SHADER_POP_H
#define SHADER_POP_H
#include <GL/glew.h>
#include "vector2.h"
#include "common.h"

// This should be enough for everyone
#define POPPING_MEMORY_USAGE 640000

#define MAX_PARTICLES 256

#define POP_UNIFORMS($) $(age) $(position) $(color) $(particle_radius)

typedef struct {
    // Relative position
    Vector2 pos;
    Vector2 d;
} PopParticle;

typedef struct {
    float starttime;
    Vector2 pos;
    Color color;
    float size;
    float pt_radius;
    GLuint vbo;
    int numparticles;
    bool alive;
    PopParticle particles[MAX_PARTICLES];
} Popping;

#define MAX_POPPING (POPPING_MEMORY_USAGE / sizeof(Popping))

#define uniform_decl($n) GLint $n;
typedef struct {
    POP_UNIFORMS(uniform_decl)
} PopUniforms;
#undef uniform_decl

typedef struct {
    GLuint program;
    GLuint vertex_array;
    Popping pops[MAX_POPPING];
    int num_popping;
    PopUniforms uniforms;
} PoppingShader;

void poppingInit(PoppingShader *sh);
void poppingPop(PoppingShader *sh, Vector2 pos, Color color, float size);
void poppingOnDraw(PoppingShader *sh, double dt);

#endif
