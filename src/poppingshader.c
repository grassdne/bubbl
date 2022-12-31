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

size_t push_particle(PoppingShader *sh, Particle particle)
{
    ParticlePool *pool = &sh->particles;
    if (pool->count >= pool->capacity) {
        grow_particle_pool(pool, pool->capacity * 2);
    }
    pool->buf[pool->count] = particle;
    return pool->count++;
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

#if 0
void create_pop(PoppingShader *sh, Vector2 pos, Color color, float size)
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
    Popping* pop = &sh->pops[n];
    pop->starttime = get_time();
    pop->pos = pos;
    pop->color = color;
    pop->alive = true;
    pop->pt_radius = PT_RADIUS;

    int count = 0;
    for (int i = 0; i < size/LAYER_WIDTH-1; i++) {
        count += PARTICLE_LAYOUT * i;
    }

    pop->particles = malloc(count * sizeof(PopParticle));
    if (pop->particles == NULL) exit(1);

    int i = 0;
    for (float r = LAYER_WIDTH; r < size - LAYER_WIDTH; r += LAYER_WIDTH) {
        int numps = PARTICLE_LAYOUT * r / LAYER_WIDTH;
        for (int j = 0; j < numps; ++j) {
            float theta = 2.0*M_PI * ((float)j / numps);
            assert(i < count);

            Vector2 rect = {cos(theta), sin(theta)};
            pop->particles[i++] = (PopParticle) {
                .pos = vec_Mult(rect, r),
                .v   = vec_Mult(rect, EXPAND_MULT * r / POP_LIFETIME),
            };
        }
    }
    pop->num_particles = count;

    glBindVertexArray(sh->shader.vao);

    glGenBuffers(1, &sh->pops[n].vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->pops[n].vbo);
	glBufferData(GL_ARRAY_BUFFER, count * sizeof(PopParticle), pop->particles, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(ATTRIB_PARTICLE_OFFSET);
    // glVertexAttribPointer needs to be called on draw
    //glVertexAttribPointer(ATTRIB_PARTICLE_OFFSET, 2, GL_FLOAT, GL_FALSE, sizeof(PopParticle), (void*)0);
    glVertexAttribDivisor(ATTRIB_PARTICLE_OFFSET, 1);

    glBindVertexArray(0);
}

void kill_popping(PoppingShader *sh, int i) {
    sh->pops[i].alive = false;
    free(sh->pops[i].particles);
    sh->pops[i].particles = NULL;
    glDeleteBuffers(1, &sh->pops[i].vbo);
}
#endif

void pop_draw(PoppingShader *sh) {
    // Bind
    glUseProgram(sh->shader.program);
    glBindVertexArray(sh->shader.vao);

    double time = get_time();

/*
    for (int i = 0; i < sh->num_popping; ++i) {
        Popping *p = &sh->pops[i];
        if (!p->alive) continue;
        if (time - p->starttime > POP_LIFETIME) {
            kill_popping(sh, i);
            continue;
        }

        p->pt_radius += PT_DELTA_RADIUS * dt;
        for (size_t j = 0; j < p->num_particles; ++j) {
            p->particles[j].pos.x += p->particles[j].v.x * dt;
            p->particles[j].pos.y += p->particles[j].v.y * dt;
        }
    glBindBuffer(GL_ARRAY_BUFFER, p->vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, p->num_particles*sizeof(PopParticle), p->particles);

    glVertexAttribPointer(ATTRIB_PARTICLE_OFFSET, 2, GL_FLOAT, GL_FALSE, sizeof(PopParticle), (void*)0);
    */

    glBindBuffer(GL_ARRAY_BUFFER, sh->particles.vbo);

    // Update buffer
    size_t sz = sh->particles.count * sizeof(Particle);

    glBufferSubData(GL_ARRAY_BUFFER, 0, sz, sh->particles.buf);
    CHECK_GL_ERROR();

    // Set uniforms
    //glUniform1f(sh->uniforms.age, time - p->starttime);
    //glUniform2f(sh->uniforms.position, p->pos.x, p->pos.y);
    //glUniform3f(sh->uniforms.color, p->color.r, p->color.g, p->color.b);
    //glUniform1f(sh->uniforms.particle_radius, p->pt_radius);
    glUniform2f(sh->uniforms.resolution, window_width, window_height);
    glUniform1f(sh->uniforms.time, time);

    // Draw
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->particles.count);

    // Unbind
    glUseProgram(0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}
