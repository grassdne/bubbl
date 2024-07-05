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
    Matrix transform;
} Entity;

typedef struct {
    Entity entity;
    Color color;
} Particle;

typedef struct  {
    Entity entity;
    Vector2 pos;
    float rad;
    Color color;
} Bubble;

typedef struct  {
    Entity entity;
    Color color;
} Test3D;

typedef struct  {
    Entity entity;
    Vector2 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} TransBubble;

void render_pop(Vector2 position, Color color, float radius);
void render_bubble(Bubble bubble);
void render_test3d(Vector2 position, Color color, float radius);
void render_trans_bubble(TransBubble bubble);

void init_renderers(void);
void flush_renderers(void);
void flush_renderer(EntityType type);

#endif
