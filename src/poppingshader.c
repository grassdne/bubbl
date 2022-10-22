#include "poppingshader.h"
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <GLFW/glfw3.h>
#include <stdlib.h>

const ShaderDatas POP_SHADER_DATAS = {
    .vert = "shaders/popbubble_quad.vert",
    .frag = "shaders/popbubble.frag",
};

typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_PARTICLE_OFFSET = 1,
} VertAttribLocs;

#define POP_LIFETIME 1.0
#define EXPAND_MULT 2.0

#define LAYER_WIDTH 10.0
#define PARTICLE_LAYOUT 5
#define PT_RADIUS 5.0;
#define PT_DELTA_RADIUS (EXPAND_MULT / POP_LIFETIME)

void poppingInit(PoppingShader *sh) {
    shaderBuildProgram((Shader*)sh, POP_SHADER_DATAS, POP_UNIFORMS);

    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    assert(get_bound_array_buffer() == 0);
}

void poppingPop(PoppingShader *sh, Vector2 pos, Color color, float size)
{
    int n = -1;
    // Recycle dead pops
    for (int i = 0; i < sh->num_popping; ++i) {
        if (!sh->pops[i].alive) {
            n = i;
            break;
        }
    }
    // Is there room for another?
    if (n < 0 && sh->num_popping < (int)MAX_POPPING) {
        n = sh->num_popping++;
    }

    if (n < 0) {
        // We reached the limit!!
        return;
    }

    sh->pops[n].starttime = glfwGetTime();
    sh->pops[n].pos = pos;
    sh->pops[n].color = color;
    sh->pops[n].size = size;
    sh->pops[n].alive = true;
    sh->pops[n].pt_radius = PT_RADIUS;

    PopParticle *ps = sh->pops[n].particles;
    int i = 0;
    for (float r = LAYER_WIDTH; r < size - LAYER_WIDTH; r += LAYER_WIDTH) {
        int numps = PARTICLE_LAYOUT * r / LAYER_WIDTH;
        for (int j = 0; j < numps; ++j) {
            float theta = 2.0*M_PI * ((float)j / numps);
            assert(i < MAX_PARTICLES);

            Vector2 rect = {cos(theta), sin(theta)};
            //printf("\t(%f, %f)\n", rect.x*r, rect.y*r);
            ps[i++] = (PopParticle) {
                .pos = vec_Mult(rect, r),
                .v   = vec_Mult(rect, EXPAND_MULT * r / POP_LIFETIME),
            };
        }
    }
    sh->pops[n].numparticles = i;

    glBindVertexArray(sh->vao);

    glGenBuffers(1, &sh->pops[n].vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->pops[n].vbo);
	glBufferData(GL_ARRAY_BUFFER, MAX_PARTICLES * sizeof(PopParticle), ps, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(ATTRIB_PARTICLE_OFFSET);
    // glVertexAttribPointer needs to be called on draw
    //glVertexAttribPointer(ATTRIB_PARTICLE_OFFSET, 2, GL_FLOAT, GL_FALSE, sizeof(PopParticle), (void*)0);
    glVertexAttribDivisor(ATTRIB_PARTICLE_OFFSET, 1);

    glBindVertexArray(0);
}

void kill_popping(PoppingShader *sh, int i) {
    sh->pops[i].alive = false;
    glDeleteBuffers(1, &sh->pops[i].vbo);
}

void poppingOnDraw(PoppingShader *sh, double dt) {
    double time = glfwGetTime();

    // Bind
    glUseProgram(sh->program);
    glBindVertexArray(sh->vao);

    for (int i = 0; i < sh->num_popping; ++i) {
        Popping *p = &sh->pops[i];
        if (!p->alive) continue;
        if (time - p->starttime > POP_LIFETIME) {
            kill_popping(sh, i);
            continue;
        }

        p->pt_radius += PT_DELTA_RADIUS * dt;
        for (int j = 0; j < p->numparticles; ++j) {
            p->particles[j].pos.x += p->particles[j].v.x * dt;
            p->particles[j].pos.y += p->particles[j].v.y * dt;
        }
        glBindBuffer(GL_ARRAY_BUFFER, p->vbo);
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(p->particles), p->particles);

        glVertexAttribPointer(ATTRIB_PARTICLE_OFFSET, 2, GL_FLOAT, GL_FALSE, sizeof(PopParticle), (void*)0);

        // Set uniforms
        glUniform1f(sh->uniforms.age, time - p->starttime);
        glUniform2f(sh->uniforms.position, p->pos.x, p->pos.y);
        glUniform3f(sh->uniforms.color, p->color.r, p->color.g, p->color.b);
        glUniform1f(sh->uniforms.particle_radius, p->pt_radius);
        glUniform2f(sh->uniforms.resolution, window_width, window_height);

        // Draw
        glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, p->numparticles);
    }

    // Unbind
    glUseProgram(0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}
