#ifndef SHADER_BUBBLE_H
#define SHADER_BUBBLE_H

#include <GL/glew.h>
#include "vector2.h"
#include "common.h"
#include "shaderutil.h"

#define BUBBLE_CAPACITY 128

#define BUBBLE_UNIFORMS($) $(time) $(resolution)

typedef struct  {
    Vector2 pos;
    Color color;
    float rad;
    Vector2 v;
    GLbyte alive;
} Bubble;

typedef struct {
    SHADER_PROGRAM_INHERIT(); 

    struct {BUBBLE_UNIFORMS(UNI_DECL)} uniforms;

    Bubble bubbles[BUBBLE_CAPACITY];
    int num_bubbles;
    GLuint bubble_vbo;
} BubbleShader;

void bubbleOnDraw(BubbleShader *sh, double dt);
void bubbleInit(BubbleShader *sh);
void bubbleCreate(BubbleShader *sh, Vector2 pos);
void bubbleOnMouseDown(BubbleShader *sh, Vector2 mouse);
void bubbleOnMouseUp(BubbleShader *sh, Vector2 mouse);
void bubbleOnMouseMove(BubbleShader *sh, Vector2 mouse);

#endif
