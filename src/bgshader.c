#include "bgshader.h"
#include "math.h"
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

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

Color color_mix(Color a, Color b, float f) {
    Color c;
    c.r = a.r * (1 - f) + b.r * f;
    c.g = a.g * (1 - f) + b.g * f;
    c.b = a.b * (1 - f) + b.b * f;
    return c;
}

void bgshader_draw(BgShader *sh, Bubble *bubbles[MAX_ELEMS], size_t num_elems)
{
    assert(num_elems <= MAX_ELEMS && "bgshader can only draw for up to MAX_ELEMS");
    glUseProgram(sh->shader.program);
    glBindVertexArray(sh->shader.vao);

    Color colors[MAX_ELEMS];
    Vector2 positions[MAX_ELEMS];

    double time = get_time();

    for (size_t i = 0; i < num_elems; ++i) {
        const Bubble *b = bubbles[i];
        if (b->trans_starttime == TRANS_STARTTIME_SENTINAL) colors[i] = b->color;
        else colors[i] = color_mix(b->color, b->trans_color, (time-b->trans_starttime)/TRANS_TIME);
        positions[i] = b->pos;
    }


    if (num_elems) {
        glUniform2f(sh->uniforms.resolution, window_width, window_height);
        glUniform1i(sh->uniforms.num_elements, num_elems);
        glUniform3fv(sh->uniforms.colors, num_elems, (float*)colors);
        glUniform2fv(sh->uniforms.positions, num_elems, (float*)positions);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }

    glBindVertexArray(0);
    glUseProgram(0);
}

