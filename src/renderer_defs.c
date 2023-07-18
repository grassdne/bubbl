#include "entity_renderer.h"
#include "renderer_defs.h"

static EntityRenderer renderers[COUNT_ENTITY_TYPES] = { 0 };
static EntityRendererData renderer_datas[COUNT_ENTITY_TYPES] = {

    [ENTITY_POP] = {
        .particle_size = sizeof(Particle),
        .shaders = {
            .vert = "shaders/popbubble_quad.vert",
            .frag = "shaders/popbubble.frag",
        },
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(Particle, pos) },
            { .id=2, GL_FLOAT, .count=4, offsetof(Particle, color) },
            { .id=3, GL_FLOAT, .count=1, offsetof(Particle, radius) },
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
            { .id=3, GL_FLOAT, .count=4, offsetof(Bubble, color_a) },
            { .id=4, GL_FLOAT, .count=4, offsetof(Bubble, color_b) },
            { .id=5, GL_FLOAT, .count=2, offsetof(Bubble, trans_angle) },
            { .id=6, GL_FLOAT, .count=1, offsetof(Bubble, trans_percent) },
        }
    },

};

// API helper functions
void render_pop(Particle particle) {
    render_entity(&renderers[ENTITY_POP], &particle);
}
void render_bubble(Bubble bubble) {
    render_entity(&renderers[ENTITY_BUBBLE], &bubble);
}

void flush_renderer(EntityType type) {
    flush_entities(&renderers[type]);
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
