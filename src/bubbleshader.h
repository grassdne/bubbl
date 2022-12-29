#ifndef SHADER_BUBBLE_H
#define SHADER_BUBBLE_H

#include <GL/glew.h>
#include "vector2.h"
#include "common.h"
#include "shaderutil.h"

#define TRANS_STARTTIME_SENTINAL -1.0
#define TRANS_TIME 1.0

#define BUBBLE_CAPACITY 128

#define BUBBLE_UNIFORMS(_) _(time) _(resolution)

typedef struct  {
    Vector2 pos;
    Vector2 v;
    Color color;
    float rad;
    GLbyte alive;
    Vector2 trans_angle;
    Color trans_color;
    double trans_starttime;
    double last_transformation;
} Bubble;

typedef struct {
    Shader shader;
    struct {BUBBLE_UNIFORMS(UNI_DECL)} uniforms;
    Bubble bubbles[BUBBLE_CAPACITY];
    size_t num_bubbles;
    GLuint bubble_vbo;
    bool paused_movement;
} BubbleShader;

void bubbleOnDraw(BubbleShader *sh, double dt);
void bubbleInit(BubbleShader *sh);
void bubbleCreate(BubbleShader *sh, Vector2 pos);
void bubbleOnMouseDown(BubbleShader *sh, Vector2 mouse);
void bubbleOnMouseUp(BubbleShader *sh, Vector2 mouse);
void bubbleOnMouseMove(BubbleShader *sh, Vector2 mouse);
size_t create_open_bubble_slot(BubbleShader *sh);
int bubble_at_point(BubbleShader *sh, Vector2 mouse);

#endif
