#ifndef SHADER_POP_H
#define SHADER_POP_H
#include <GL/glew.h>
#include "common.h"
#include "shaderutil.h"

#define POP_UNIFORMS(_) _(resolution) _(time)

typedef struct {
    // Relative position
    Vector2 pos;
    Vector2 v;
} PopParticle;

typedef struct { POP_UNIFORMS(UNI_DECL) } PopUniforms;

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
    float age;
} Particle;

typedef struct {
    Particle *buf;
    size_t count, capacity;
    GLuint vbo;
} ParticlePool;

typedef struct {
    Shader shader;
    ParticlePool particles;
    PopUniforms uniforms;
} PoppingShader;

void poppingInit(PoppingShader *sh);

#endif
