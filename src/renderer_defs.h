#ifndef ENTITY_RENDERERS_H
#define ENTITY_RENDERERS_H
#include "common.h"
#include "raymath.h"

typedef enum {
    ENTITY_BUBBLE,
    ENTITY_POP,
    ENTITY_TRANS_BUBBLE,
    ENTITY_TEST3D,
    COUNT_ENTITY_TYPES,
} EntityType;

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
} Particle;

typedef struct  {
    Vector2 pos;
    float rad;
    Color color;
} Bubble;

typedef struct  {
    Vector2 pos;
    float rad;
    Color color;
} Test3D;

typedef struct  {
    Vector2 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} TransBubble;

void render_pop(Particle particle);
void render_bubble(Bubble bubble);
void render_test3d(Test3D bubble);
void render_trans_bubble(TransBubble bubble);

void init_renderers(void);
void flush_renderers(void);
void flush_renderer(EntityType type);

#endif
