#ifndef SHADER_POP_H
#define SHADER_POP_H
#include <GL/glew.h>
#include "common.h"
#include "shaderutil.h"

// should be enough for everybody
#define PARTICLES_MEMORY_USAGE (640000)
#define PARTICLES_BUFFER_SIZE (PARTICLES_MEMORY_USAGE / sizeof(Particle))
#define POP_UNIFORMS(_) _(resolution) _(time)

typedef struct { POP_UNIFORMS(UNI_DECL) } PopUniforms;

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
    float age;
} Particle;

typedef struct {
    Shader shader;
    PopUniforms uniforms;
    Particle particle_buffer[PARTICLES_BUFFER_SIZE];
    size_t nparticles;
    GLuint vbo;
} PoppingShader;

void poppingInit(PoppingShader *sh);

#endif
