#ifndef ENTITY_RENDERERS_H
#define ENTITY_RENDERERS_H
#include "common.h"

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
} Particle;

typedef struct  {
    Vector2 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} Bubble;

void render_pop(Particle particle);
void render_bubble(Bubble bubble);

void init_renderers(void);
void flush_renderers(void);

#endif
