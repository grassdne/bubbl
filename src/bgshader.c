#include "bgshader.h"
#include "math.h"
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_ELEMS 10

const ShaderDatas BG_SHADER_DATAS = {
    .vert = "shaders/bg.vert",
    .frag = "shaders/bg.frag",
};

void bgInit(BgShader* restrict sh, Bubble *bubbles, size_t *numbbls) {
    sh->bubbles = bubbles;
    sh->numbbls = numbbls;

   shaderBuildProgram(sh, BG_SHADER_DATAS, BG_UNIFORMS); 
}

static Bubble *bubbles;
static int compare(const void *a, const void *b) {
    int i = *(int*)a;
    int j = *(int*)b;
    return bubbles[i].rad < bubbles[j].rad;
}

Color color_mix(Color a, Color b, float f) {
    Color c;
    c.r = a.r * (1 - f) + b.r * f;
    c.g = a.g * (1 - f) + b.g * f;
    c.b = a.b * (1 - f) + b.b * f;
    return c;
}

void bgOnDraw(BgShader *sh, double dt) {
    (void)dt;
    glUseProgram(sh->program);
    glBindVertexArray(sh->vao);

    Color colors[MAX_ELEMS];
    Vector2 positions[MAX_ELEMS];

    int indices[BUBBLE_CAPACITY];
    int len;

    int i, j;
    for (i = 0, j = 0; j < BUBBLE_CAPACITY; ++j) {
        if (sh->bubbles[j].alive) {
            indices[i] = j;
            ++i;
        }
    }
    len = i;
    bubbles = sh->bubbles;
    qsort((void*)indices, (size_t)len, sizeof(int), &compare);

    double time = glfwGetTime();

    for (int i = 0; i < len && i < MAX_ELEMS; ++i) {
        const Bubble *b = &sh->bubbles[indices[i]];
        if (b->trans_starttime == TRANS_STARTTIME_SENTINAL) colors[i] = b->color;
        else colors[i] = color_mix(b->color, b->trans_color, (time-b->trans_starttime)/TRANS_TIME);
        positions[i] = b->pos;
    }


    if (len) {
        glUniform2f(sh->uniforms.resolution, window_width, window_height);
        glUniform1i(sh->uniforms.num_elements, len);
        glUniform3fv(sh->uniforms.colors, len, (float*)colors);
        glUniform2fv(sh->uniforms.positions, len, (float*)positions);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }

    glBindVertexArray(0);
    glUseProgram(0);
}

