/*
 * These are the definitions for rendering different kinds of
 * "entities" that can be batch rendered. Adding a new entity
 * is just adding a new entry into the entity table and adding
 * a helper functions to easily render entities.
*/

#include "SDL_video.h"
#include "common.h"
#include "geometry_defs.h"
#include "entity_renderer.h"
#include "raymath.h"
#include "renderer_defs.h"

typedef struct  {
    Color color;
} Test3D;

typedef struct {
    Color color;
} Particle;

typedef struct {
    Color color;
} Box;

typedef enum {
    ENTITY_BUBBLE,
    ENTITY_POP,
    ENTITY_TRANS_BUBBLE,
    ENTITY_TEST3D,
    ENTITY_BOX,
    COUNT_ENTITY_TYPES,
} EntityType;

static EntityRenderer renderers[COUNT_ENTITY_TYPES] = { 0 };
static EntityRendererData renderer_datas[COUNT_ENTITY_TYPES] = {
    [ENTITY_POP] = {
        .particle_size = sizeof(Particle),
        .geometry = &QUAD_GEOMETRY,
        .vert = "shaders/popbubble_quad.vert",
        .frag = "shaders/popbubble.frag",
        .attributes = {
            { .id=2, GL_FLOAT, .count=4, offsetof(Particle, color) },
        },
        .is_transparent = true,
    },

    [ENTITY_BUBBLE] = {
        .particle_size = sizeof(Bubble),
        .geometry = &QUAD_GEOMETRY,
        .vert = "shaders/bubble_quad.vert",
        .frag = "shaders/bubble.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(Bubble, pos) },
            { .id=2, GL_FLOAT, .count=1, offsetof(Bubble, rad) },
            { .id=3, GL_FLOAT, .count=4, offsetof(Bubble, color) },
        },
        .is_transparent = true,
    },

    [ENTITY_TEST3D] = {
        .particle_size = sizeof(Test3D),
        .geometry = &QUAD_GEOMETRY,
        .vert = "shaders/test3d.vert",
        .frag = "shaders/test3d.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=4, offsetof(Test3D, color) },
        },
        .is_transparent = true,

    },

    [ENTITY_BOX] = {
        .particle_size = sizeof(Box),
        .geometry = &CUBE_GEOMETRY,
        .vert = "shaders/box.vert",
        .frag = "shaders/box.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=4, offsetof(Box, color) },
        },
        .is_transparent = false,
    },

    [ENTITY_TRANS_BUBBLE] = {
        .particle_size = sizeof(TransBubble),
        .geometry = &QUAD_GEOMETRY,
        .vert = "shaders/transbubble_quad.vert",
        .frag = "shaders/transbubble.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(TransBubble, pos) },
            { .id=2, GL_FLOAT, .count=1, offsetof(TransBubble, rad) },
            { .id=3, GL_FLOAT, .count=4, offsetof(TransBubble, color_a) },
            { .id=4, GL_FLOAT, .count=4, offsetof(TransBubble, color_b) },
            { .id=5, GL_FLOAT, .count=2, offsetof(TransBubble, trans_angle) },
            { .id=6, GL_FLOAT, .count=1, offsetof(TransBubble, trans_percent) },
        },
        .is_transparent = true,
    },

};

// Normalize Device Coordinates
Vector3 normalized(Vector3 position) {
    float aspect = (float)drawing_width / (float)drawing_height;
    return (Vector3) {
        .x = position.x / (float)drawing_width * 2.0f * aspect - aspect,
        .y = position.y / (float)drawing_height * 2.0f - 1.0f,
        .z = position.z / (float)drawing_height,
    };
}

Matrix gen_model(Vector3 position, float radius) {
    // radius in [0, 2] scale
    radius = 2.0f * radius / (float)drawing_height;

    // bubble position [-1, 1] scale
    position = normalized(position);

    Matrix model = MatrixIdentity();
    model = MatrixMultiply(model, MatrixScale(radius, radius, 1.0f));
    /*Vector3 axis = (Vector3) { 1.0f, 0.0f, 0.0f};*/
    /*model = MatrixMultiply(model, MatrixRotate(axis, PI * get_time()));*/
    model = MatrixMultiply(model, MatrixTranslate(position.x, position.y, position.z));
    return model;
}

// API helper functions
void render_pop(Vector3 position, Color color, float radius)
{
    Particle particle = {
        .color = color,
    };
    render_entity(&renderers[ENTITY_POP], &particle, gen_model(position, radius));
}

void render_bubble(Bubble bubble) {
    render_entity(&renderers[ENTITY_BUBBLE], &bubble, MatrixIdentity());
}

void render_test3d(Vector3 position, Color color, float radius)
{
    Test3D bubble = {
        .color = color,
    };
    render_entity(&renderers[ENTITY_TEST3D], &bubble, gen_model(position, radius));
}

void render_trans_bubble(TransBubble bubble) {
    render_entity(&renderers[ENTITY_TRANS_BUBBLE], &bubble, MatrixIdentity());
}

void render_box(Vector3 position, Color color, float size)
{
    /*glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );*/
    Box box = {
        .color = color,
    };

    position = normalized(position);
    size = size * 2.0f / (float)drawing_height;

    Matrix model = MatrixIdentity();
    model = MatrixMultiply(model, MatrixScale(size, size, size));
    Vector3 axis = (Vector3) { 1.0f, 1.0f, 0.0f};
    model = MatrixMultiply(model, MatrixRotate(axis, 0.25 * PI * get_time()));
    model = MatrixMultiply(model, MatrixTranslate(position.x, position.y, position.z));

    render_entity(&renderers[ENTITY_BOX], &box, model);
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
