#ifndef SHADER_BUBBLE_H
#define SHADER_BUBBLE_H

#include <GL/glew.h>
#include "vector2.h"

#define uniform_decl($n) GLint $n;

#define BUBBLE_CAPACITY 100

#define BUBBLE_UNIFORMS($) $(time) $(resolution)

typedef struct {
    float r, g, b;
} Color;

typedef struct  {
    Vector2 pos;
    Color color;
    float rad;
    Vector2 d;
    GLbyte alive;
} Bubble;

typedef struct {
    BUBBLE_UNIFORMS(uniform_decl)
} Uniforms;
#undef uniform_decl

typedef struct {
    GLuint program;
    Bubble bubbles[BUBBLE_CAPACITY];
    int num_bubbles;
    GLuint bubble_vbo;
    Uniforms uniforms;
} BubbleShader;

void bubbleOnMouseDown(BubbleShader *sh, Vector2 mouse);
void bubbleOnDraw(BubbleShader *sh, double dt);
void bubbleInit(BubbleShader *sh);

#endif
