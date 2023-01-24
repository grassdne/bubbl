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
    ATTRIB_VERT_POS=0,
    ATTRIB_POSITION,
    ATTRIB_COLOR,
    ATTRIB_RADIUS,
    ATTRIB_AGE,
} VertAttribLocs;

void flush_particles(PoppingShader *sh)
{
    // Bind
    glUseProgram(sh->shader.program);
    glBindVertexArray(sh->shader.vao);
	glBindBuffer(GL_ARRAY_BUFFER, sh->vbo);

    double time = get_time();

    // Update buffer
    glBufferSubData(GL_ARRAY_BUFFER, 0, PARTICLES_BUFFER_SIZE * sizeof(Particle), sh->particle_buffer);

    CHECK_GL_ERROR();
    glUniform2f(sh->uniforms.resolution, window_width, window_height);
    glUniform1f(sh->uniforms.time, time);

    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->nparticles);

    // Unbind
    glUseProgram(0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // Reset pool
    sh->nparticles = 0;
}

void render_particle(PoppingShader *sh, Particle particle)
{
    if (sh->nparticles >= PARTICLES_BUFFER_SIZE) {
        flush_particles(sh);
    }
    sh->particle_buffer[sh->nparticles++] = particle;
}

#define POP_ATTRIB(loc, count, type, field) do{                         \
    glEnableVertexAttribArray(loc);                                     \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Particle), \
                          (void*)offsetof(Particle, field));            \
    glVertexAttribDivisor(loc, 1);                                      \
}while(0)

void poppingInit(PoppingShader *sh) {
    shaderBuildProgram(sh, POP_SHADER_DATAS, POP_UNIFORMS);

    glGenBuffers(1, &sh->vbo);
    glBindBuffer(GL_ARRAY_BUFFER, sh->vbo);
    glBufferData(GL_ARRAY_BUFFER, PARTICLES_BUFFER_SIZE * sizeof(Particle), sh->particle_buffer, GL_DYNAMIC_DRAW);

    POP_ATTRIB(ATTRIB_POSITION, 2, GL_FLOAT, pos);
    POP_ATTRIB(ATTRIB_COLOR   , 3, GL_FLOAT, color);
    POP_ATTRIB(ATTRIB_RADIUS  , 1, GL_FLOAT, radius);
    POP_ATTRIB(ATTRIB_AGE     , 1, GL_FLOAT, age);

    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    CHECK_GL_ERROR();
}
