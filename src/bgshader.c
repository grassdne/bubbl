#include "bgshader.h"
#include "math.h"
#include <stdio.h>
#include <stdlib.h>

#define MAX_ELEMS 10

const ShaderDatas BG_SHADER_DATAS = {
    .vert = "shaders/bg.vert",
    .frag = "shaders/bg.frag",
};

void bgInit(BgShader* restrict sh, Bubble *bubbles, int *numbbls) {
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

    for (int i = 0; i < len && i < MAX_ELEMS; ++i) {
        int idx = indices[i];
        colors[i] = sh->bubbles[idx].color;
        positions[i] = sh->bubbles[idx].pos;
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

