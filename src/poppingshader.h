#ifndef SHADER_POP_H
#define SHADER_POP_H
#include "common.h"
#include "shaderutil.h"

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
    float age;
} Particle;

void poppingInit(void);
void render_pop(Particle particle);
void flush_pops(void);

#endif
