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

#define PARTICLES_INIT_CAPACITY 1024

static void grow_particlepool(ParticlePool *pool) {
    pool->capacity = pool->capacity == 0
                   ? PARTICLES_INIT_CAPACITY
                   : pool->capacity * 2;
    pool->buf = realloc(pool->buf, pool->capacity * sizeof(Particle));
    assert(pool->buf && "not enough memory");
}

void render_particle(PoppingShader *sh, Particle particle)
{
    if (sh->particles.count >= sh->particles.capacity) {
        grow_particlepool(&sh->particles);
    }
    sh->particles.buf[sh->particles.count++] = particle;
}

#define POP_ATTRIB(loc, count, type, field) do{                         \
    glEnableVertexAttribArray(loc);                                     \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Particle), \
                          (void*)offsetof(Particle, field));            \
    glVertexAttribDivisor(loc, 1);                                      \
}while(0)

void poppingInit(PoppingShader *sh) {
    shaderBuildProgram(sh, POP_SHADER_DATAS, POP_UNIFORMS);

    glGenBuffers(1, &sh->particles.vbo);
    glBindBuffer(GL_ARRAY_BUFFER, sh->particles.vbo);

    POP_ATTRIB(ATTRIB_POSITION, 2, GL_FLOAT, pos);
    POP_ATTRIB(ATTRIB_COLOR   , 3, GL_FLOAT, color);
    POP_ATTRIB(ATTRIB_RADIUS  , 1, GL_FLOAT, radius);
    POP_ATTRIB(ATTRIB_AGE     , 1, GL_FLOAT, age);

    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    CHECK_GL_ERROR();
}

void flush_particles(PoppingShader *sh) {
    // Bind
    glUseProgram(sh->shader.program);
    glBindVertexArray(sh->shader.vao);
	glBindBuffer(GL_ARRAY_BUFFER, sh->particles.vbo);

    double time = get_time();

    // Update buffer
	glBufferData(GL_ARRAY_BUFFER, sh->particles.capacity * sizeof(Particle), sh->particles.buf, GL_STATIC_DRAW);
    CHECK_GL_ERROR();

    glUniform2f(sh->uniforms.resolution, window_width, window_height);
    glUniform1f(sh->uniforms.time, time);

    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->particles.count);

    glUseProgram(0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // Clear pool
    free(sh->particles.buf);
    sh->particles.buf = NULL;
    sh->particles.count = 0;
    sh->particles.capacity = 0;
}
