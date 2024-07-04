/*
 * These are the definitions for rendering different kinds of
 * "entities" that can be batch rendered. Adding a new entity
 * is just adding a new entry into the entity table and adding
 * a helper functions to easily render entities.
*/

#include "SDL_video.h"
#include "common.h"
#include "entity_renderer.h"
#include "raymath.h"
#include "renderer_defs.h"

static EntityRenderer renderers[COUNT_ENTITY_TYPES] = { 0 };
static EntityRendererData renderer_datas[COUNT_ENTITY_TYPES] = {
    [ENTITY_POP] = {
        .particle_size = sizeof(Particle),
        .vertices = QUAD,
        .vertex_count = 4,
        .vert = "shaders/popbubble_quad.vert",
        .frag = "shaders/popbubble.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(Particle, pos) },
            { .id=2, GL_FLOAT, .count=4, offsetof(Particle, color) },
            { .id=3, GL_FLOAT, .count=1, offsetof(Particle, radius) },
        },
    },

    [ENTITY_BUBBLE] = {
        .particle_size = sizeof(Bubble),
        .vertices = QUAD,
        .vertex_count = 4,
        .vert = "shaders/bubble_quad.vert",
        .frag = "shaders/bubble.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(Bubble, pos) },
            { .id=2, GL_FLOAT, .count=1, offsetof(Bubble, rad) },
            { .id=3, GL_FLOAT, .count=4, offsetof(Bubble, color) },
        }
    },

    [ENTITY_TEST3D] = {
        .particle_size = sizeof(Test3D),
        .vertices = QUAD,
        .vertex_count = 4,
        .vert = "shaders/test3d.vert",
        .frag = "shaders/test3d.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=4, offsetof(Test3D, color) },
            { .id=9, GL_FLOAT, .count=4, offsetof(Test3D, transform) + sizeof(Vector4) * 0 },
            { .id=10, GL_FLOAT, .count=4, offsetof(Test3D, transform) + sizeof(Vector4) * 1 },
            { .id=11, GL_FLOAT, .count=4, offsetof(Test3D, transform) + sizeof(Vector4) * 2 },
            { .id=12, GL_FLOAT, .count=4, offsetof(Test3D, transform) + sizeof(Vector4) * 3 },
        }
    },

    [ENTITY_TRANS_BUBBLE] = {
        .particle_size = sizeof(TransBubble),
        .vertices = QUAD,
        .vertex_count = 4,
        .vert = "shaders/transbubble_quad.vert",
        .frag = "shaders/transbubble.frag",
        .attributes = {
            { .id=1, GL_FLOAT, .count=2, offsetof(TransBubble, pos) },
            { .id=2, GL_FLOAT, .count=1, offsetof(TransBubble, rad) },
            { .id=3, GL_FLOAT, .count=4, offsetof(TransBubble, color_a) },
            { .id=4, GL_FLOAT, .count=4, offsetof(TransBubble, color_b) },
            { .id=5, GL_FLOAT, .count=2, offsetof(TransBubble, trans_angle) },
            { .id=6, GL_FLOAT, .count=1, offsetof(TransBubble, trans_percent) },
        }
    },

};

static Matrix gen_view(Vector2 resolution) {
    (void)resolution;
    Vector3 eye = { 0.0f, 0.0f, 1.0f };
    Vector3 target = { 0.0f, 0.0f, 0.0f };
    Vector3 up = { 0.0f, 1.0f, 0.0f };
    return MatrixLookAt(eye, target, up);
}

Matrix gen_projection(Vector2 resolution) {
    return MatrixPerspective(0.5 * PI, resolution.x / resolution.y, 0.1, 100.0);
}

Matrix gen_model(Vector2 resolution, Vector3 position, float radius) {
    // radius in [0, 2] scale
    float r = 2.0f * radius / resolution.y;
    // bubble position [-1, 1] scale
    float aspect = resolution.x / resolution.y;
    Vector3 pos = {
        .x = position.x / resolution.x * 2.0f * aspect - aspect,
        .y = position.y / resolution.y * 2.0f - 1.0f,
        .z = 0.0f,
    };

    Matrix model = MatrixIdentity();
    model = MatrixMultiply(model, MatrixScale(r, r, r));
    /*Vector3 axis = (Vector3) { 1.0f, 0.0f, 0.0f};*/
    /*model = MatrixMultiply(model, MatrixRotate(axis, PI * get_time()));*/
    model = MatrixMultiply(model, MatrixTranslate(pos.x, pos.y, pos.z));
    return model;
}

static Matrix gen_transform(Vector2 resolution, Vector3 position, float radius) {
    Matrix transform = MatrixIdentity();
    transform = MatrixMultiply(transform, gen_model(resolution, position, radius));
    transform = MatrixMultiply(transform, gen_view(resolution));
    transform = MatrixMultiply(transform, gen_projection(resolution));
    return transform;
}


// API helper functions
void render_pop(Particle particle) {
    render_entity(&renderers[ENTITY_POP], &particle);
}
void render_bubble(Bubble bubble) {
    render_entity(&renderers[ENTITY_BUBBLE], &bubble);
}
void render_test3d(Vector2 position, Color color, float radius) {
    SDL_Window *window = SDL_GL_GetCurrentWindow();
    int w, h;
    SDL_GL_GetDrawableSize(window, &w, &h);
    Vector2 resolution = { (float)w, (float)h };
    Vector3 pos = (Vector3){ position.x, position.y, 0.0f };

    Matrix transform = gen_transform(resolution, pos, radius);
    
    Test3D bubble = {
        .color = color,
        .transform = MatrixTranspose(transform),
        /*.transform = MatrixTranspose(MatrixIdentity()),*/
    };
    render_entity(&renderers[ENTITY_TEST3D], &bubble);
}
void render_trans_bubble(TransBubble bubble) {
    render_entity(&renderers[ENTITY_TRANS_BUBBLE], &bubble);
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
