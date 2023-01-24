#ifndef SHADER_BUBBLE_H
#define SHADER_BUBBLE_H

#include <GL/glew.h>
#include "shaderutil.h"
#include "common.h"

#define TRANS_STARTTIME_SENTINAL -1.0
#define TRANS_TIME 1.0

#define BUBBLE_CAPACITY 128

#define BUBBLE_UNIFORMS(_) _(time) _(resolution)

typedef struct  {
    Vector2 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} Bubble;

typedef struct {
    Shader shader;
    struct {BUBBLE_UNIFORMS(UNI_DECL)} uniforms;
    Bubble bubbles[BUBBLE_CAPACITY];
    size_t num_bubbles;
    GLuint bubble_vbo;
    bool paused_movement;
} BubbleShader;

void bubbleInit(BubbleShader *sh);
void bubbleCreate(BubbleShader *sh, Vector2 pos);
int bubble_at_point(BubbleShader *sh, Vector2 mouse);

#endif
