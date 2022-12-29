#ifndef SHADER_POP_H
#define SHADER_POP_H
#include <GL/glew.h>
#include "vector2.h"
#include "common.h"
#include "shaderutil.h"

// only 64 popping effects at once
#define MAX_POPPING 64
//#define MAX_PARTICLES 512

#define POP_UNIFORMS($) $(age) $(position) $(color) $(particle_radius) $(resolution) $(size)

typedef struct {
    // Relative position
    Vector2 pos;
    Vector2 v;
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
    //PopParticle particles[MAX_PARTICLES];
    PopParticle *particles;
} Popping;


typedef struct { POP_UNIFORMS(UNI_DECL) } PopUniforms;

typedef struct {
    Shader shader;
    Popping pops[MAX_POPPING];
    int num_popping;
    PopUniforms uniforms;
} PoppingShader;

void poppingInit(PoppingShader *sh);
void poppingPop(PoppingShader *sh, Vector2 pos, Color color, float size);
void poppingOnDraw(PoppingShader *sh, double dt);

#endif
