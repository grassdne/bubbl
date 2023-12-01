#ifndef SHADER_POP_H
#define SHADER_POP_H
#include "common.h"
#include "shaderutil.h"

typedef struct {
    int id;
    GLenum type;
    int count;
    size_t offset;
} Attribute;

#define ENTITY_RENDERER_DATA_MAX_ATTRIBUTES 16
typedef struct {
    size_t particle_size;
    const char *frag;
    const char *vert;
    Attribute attributes[ENTITY_RENDERER_DATA_MAX_ATTRIBUTES];
} EntityRendererData;

// Each entity renderer uses up to ENTITIY_BUFFER_SIZE bytes of memory
#define ENTITIY_BUFFER_SIZE 500000

typedef struct {
    Shader shader;
    struct {
        GLint time;
        GLint resolution;
    } uniforms;
    char buffer[ENTITIY_BUFFER_SIZE];
    size_t num_entities;
    size_t buffer_size;
    size_t entity_size;
    GLuint vbo;
} EntityRenderer;

typedef enum {
    ENTITY_BUBBLE,
    ENTITY_POP,
    COUNT_ENTITY_TYPES,
} EntityType;

void entity_init(EntityRenderer *r, const EntityRendererData data);
void flush_entities(EntityRenderer *r);
void render_entity(EntityRenderer *restrict r, const void *restrict entity);
void flush_renderer(EntityType type);

#endif
