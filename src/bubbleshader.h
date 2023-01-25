#ifndef SHADER_BUBBLE_H
#define SHADER_BUBBLE_H

#include <GL/glew.h>
#include "shaderutil.h"
#include "common.h"

typedef struct  {
    Vector2 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} Bubble;

void bubbleInit(void);
void bubbleCreate(Vector2 pos);
void flush_bubbles(void);

#endif
