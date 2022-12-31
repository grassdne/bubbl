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
    ATTRIB_POSITION = 1,
    ATTRIB_COLOR = 2,
    ATTRIB_RADIUS = 3,
    ATTRIB_AGE = 4,
    ATTRIB_ALIVE = 5,
} VertAttribLocs;

#define POP_LIFETIME 1.0
#define EXPAND_MULT 2.0

#define LAYER_WIDTH SCALECONTENT(10.0)
#define PARTICLE_LAYOUT 5
#define PT_RADIUS SCALECONTENT(8.0);
#define PT_DELTA_RADIUS (EXPAND_MULT / POP_LIFETIME)

#define PARTICLES_INIT_CAPACITY 1024

#define POP_ATTRIB(loc, count, type, field) do{                         \
    glEnableVertexAttribArray(loc);                                     \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Particle), \
                          (void*)offsetof(Particle, field));            \
    glVertexAttribDivisor(loc, 1);                                      \
}while(0)

void grow_particle_pool(ParticlePool *pool, size_t new_capacity) {
    pool->buf = realloc(pool->buf, (pool->capacity = new_capacity) * sizeof(Particle));
    assert(pool->buf && "not enough memory");
    // We need to generate a new data store when it grows
	glBindBuffer(GL_ARRAY_BUFFER, pool->vbo);
    printf("glBufferData size = %zu\n", pool->capacity * sizeof(Particle));
	glBufferData(GL_ARRAY_BUFFER, pool->capacity * sizeof(Particle), pool->buf, GL_DYNAMIC_DRAW);
}

void init_particles(ParticlePool *particles) {
    grow_particle_pool(particles, PARTICLES_INIT_CAPACITY);
}

// TODO: consider caching dead bubbles to avoid linear iteration
// Adding thousands of particles at once should be nothing
static size_t make_empty_space(PoppingShader *sh) {
    ParticlePool *pool = &sh->particles;
    for (size_t i = 0; i < pool->count; i++) {
        if (pool->buf[i].alive == false) return i;
    }
    if (pool->count >= pool->capacity) {
        grow_particle_pool(pool, pool->capacity * 2);
    }
    return pool->count++;
}

size_t push_particle(PoppingShader *sh, Particle particle)
{
    size_t pos = make_empty_space(sh);
    sh->particles.buf[pos] = particle;
    return pos;
}

Particle *pop_get_particle(PoppingShader *sh, size_t id)
{
    assert(id < sh->particles.count && "pop particle id out of range");
    assert(sh->particles.buf[id].alive && "requested dead pop particle");
    return &sh->particles.buf[id];
}

void poppingInit(PoppingShader *sh) {
    shaderBuildProgram((Shader*)sh, POP_SHADER_DATAS, POP_UNIFORMS);

    glGenBuffers(1, &sh->particles.vbo);
    init_particles(&sh->particles);

    POP_ATTRIB(ATTRIB_POSITION, 2, GL_FLOAT, pos);
    POP_ATTRIB(ATTRIB_COLOR, 3, GL_FLOAT, color);
    POP_ATTRIB(ATTRIB_RADIUS, 1, GL_FLOAT, radius);
    POP_ATTRIB(ATTRIB_AGE, 1, GL_FLOAT, age);
    POP_ATTRIB(ATTRIB_ALIVE, 1, GL_BYTE, alive);

    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

}

void pop_draw(PoppingShader *sh) {
    // Bind
    glUseProgram(sh->shader.program);
    glBindVertexArray(sh->shader.vao);
    glBindBuffer(GL_ARRAY_BUFFER, sh->particles.vbo);

    double time = get_time();

    // Update buffer
    glBufferSubData(GL_ARRAY_BUFFER, 0, sh->particles.count * sizeof(Particle), sh->particles.buf);
    CHECK_GL_ERROR();

    glUniform2f(sh->uniforms.resolution, window_width, window_height);
    glUniform1f(sh->uniforms.time, time);

    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->particles.count);

    glUseProgram(0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}
