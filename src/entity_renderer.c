#include "entity_renderer.h"
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <GLFW/glfw3.h>
#include <stdlib.h>

static EntityRendererData renderer_datas[COUNT_ENTITY_TYPES] = {
    [ENTITY_POP] = {
        .particle_size = sizeof(Particle),
        .shaders = {
            .vert = "shaders/popbubble_quad.vert",
            .frag = "shaders/popbubble.frag",
        },
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(Particle, pos) },
            { .id=2, GL_FLOAT, .count=3, offsetof(Particle, color) },
            { .id=3, GL_FLOAT, .count=1, offsetof(Particle, radius) },
            { .id=4, GL_FLOAT, .count=1, offsetof(Particle, age) },
        },
    },

    [ENTITY_BUBBLE] = {
        .particle_size = sizeof(Bubble),
        .shaders = {
            .vert = "shaders/bubble_quad.vert",
            .frag = "shaders/bubble.frag",
        },
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(Bubble, pos) },
            { .id=2, GL_FLOAT, .count=1, offsetof(Bubble, rad) },
            { .id=3, GL_FLOAT, .count=3, offsetof(Bubble, color_a) },
            { .id=4, GL_FLOAT, .count=3, offsetof(Bubble, color_b) },
            { .id=5, GL_FLOAT, .count=2, offsetof(Bubble, trans_angle) },
            { .id=6, GL_FLOAT, .count=1, offsetof(Bubble, trans_percent) },
        }
    },
};

static EntityRenderer renderers[COUNT_ENTITY_TYPES] = { 0 };

void flush_renderer(EntityType type) {
    flush_entities(&renderers[type]);
}

void render_pop(Particle particle) {
    render_entity(&renderers[ENTITY_POP], &particle);
}
void render_bubble(Bubble bubble) {
    render_entity(&renderers[ENTITY_BUBBLE], &bubble);
}

void entity_init(EntityRenderer *r, const EntityRendererData data) {
    shaderBuildProgram(&r->shader, data.shaders, ENTITY_UNIFORMS);
    r->uniforms.resolution = glGetUniformLocation(r->shader.program, "resolution");
    r->uniforms.time = glGetUniformLocation(r->shader.program, "time");

    r->num_entities = 0;
    r->entity_size = data.particle_size;

    // Create vertex buffer object
    r->buffer_size = ENTITIY_BUFFER_SIZE / data.particle_size;
    r->buffer = malloc(ENTITIY_BUFFER_SIZE);
    glBindVertexArray(r->shader.vao);
    glGenBuffers(1, &r->vbo);
    glBindBuffer(GL_ARRAY_BUFFER, r->vbo);
    glBufferData(GL_ARRAY_BUFFER, ENTITIY_BUFFER_SIZE, r->buffer, GL_DYNAMIC_DRAW);

    // Initialize attributes
    for (const Attribute *attr = data.attributes; attr->count > 0; attr++) {
        glEnableVertexAttribArray(attr->id);
        glVertexAttribPointer(attr->id, attr->count, attr->type, GL_FALSE, data.particle_size, (void*)attr->offset);
        glVertexAttribDivisor(attr->id, 1);
    }

    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

void flush_renderers(void)
{
    for (EntityType i = 0; i < COUNT_ENTITY_TYPES; i++) {
        flush_entities(&renderers[i]);
    }
}

void init_renderers(void)
{
    for (EntityType i = 0; i < COUNT_ENTITY_TYPES; i++) {
        entity_init(&renderers[i], renderer_datas[i]);
    }
}

void flush_entities(EntityRenderer *r)
{
    glUseProgram(r->shader.program);
    glBindVertexArray(r->shader.vao);
    glBindBuffer(GL_ARRAY_BUFFER, r->vbo);

    double time = get_time();

    glBufferSubData(GL_ARRAY_BUFFER, 0, ENTITIY_BUFFER_SIZE, r->buffer);

    glUniform2f(r->uniforms.resolution, window_width, window_height);
    glUniform1f(r->uniforms.time, time);

    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, r->num_entities);
    
    // Reset buffer
    r->num_entities = 0;

    // Unbind
    glUseProgram(0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void render_entity(EntityRenderer *restrict r, const void *restrict entity)
{
    if (r->num_entities >= r->buffer_size) {
        flush_entities(r);
    }
    void *top = (char*)r->buffer + (r->num_entities * r->entity_size);
    memcpy(top, entity, r->entity_size);
    r->num_entities += 1;
}
