#ifndef SHADER_BUBBLE_H
#define SHADER_BUBBLE_H

#include <GL/glew.h>
#include "vector2.h"
#include "common.h"

#define BUBBLE_CAPACITY 128

#define BUBBLE_UNIFORMS($) $(time) $(resolution)

typedef struct  {
    Vector2 pos;
    Color color;
    float rad;
    Vector2 d;
    GLbyte alive;
} Bubble;

#define uniform_decl($n) GLint $n;
typedef struct {
    BUBBLE_UNIFORMS(uniform_decl)
} BubbleUniforms;
#undef uniform_decl

typedef struct {
    GLuint program;
    GLuint vertex_array;

    Bubble bubbles[BUBBLE_CAPACITY];
    int num_bubbles;
    GLuint bubble_vbo;
    BubbleUniforms uniforms;
    int growing;
} BubbleShader;

void bubbleOnDraw(BubbleShader *sh, double dt);
void bubbleInit(BubbleShader *sh);
int bubbleIsAtPoint(BubbleShader *sh, Vector2 mouse);
int bubbleCreate(BubbleShader *sh, bool togrow, float x, float y);
void bubbleOnMouseDown(BubbleShader *sh, Vector2 mouse);
void bubbleOnMouseUp(BubbleShader *sh, Vector2 mouse);
void bubbleOnMouseMove(BubbleShader *sh, Vector2 mouse);

#endif
