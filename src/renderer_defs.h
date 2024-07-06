#ifndef ENTITY_RENDERERS_H
#define ENTITY_RENDERERS_H
#include "common.h"
#include "raymath.h"

typedef struct  {
    Vector3 pos;
    float rad;
    Color color;
} Bubble;

typedef struct  {
    Vector3 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} TransBubble;

void render_pop(Vector3 position, Color color, float radius);
void render_bubble(Bubble bubble);
void render_test3d(Vector3 position, Color color, float radius);
void render_trans_bubble(TransBubble bubble);
void render_box(Vector3 position, Color color, float size);

void init_renderers(void);
void flush_renderers(void);

#endif
