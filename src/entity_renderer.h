#ifndef SHADER_POP_H
#define SHADER_POP_H
#include "common.h"
#include "shaderutil.h"

typedef struct {
    Vector2 pos;
    Color color;
    float radius;
    float age;
} Particle;

typedef struct  {
    Vector2 pos;
    float rad;
    Color color_a;
    Color color_b;
    Vector2 trans_angle;
    float trans_percent;
} Bubble;

typedef struct {
    int id;
    GLenum type;
    int count;
    size_t offset;
} Attribute;

#define ENTITY_RENDERER_DATA_MAX_ATTRIBUTES 16
typedef struct {
    size_t particle_size;
    ShaderDatas shaders;
    Attribute attributes[ENTITY_RENDERER_DATA_MAX_ATTRIBUTES];
} EntityRendererData;

#define ENTITIY_BUFFER_SIZE 500000

typedef struct {
    Shader shader;
    struct {
        GLint time;
        GLint resolution;
    } uniforms;
    void *buffer;
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

void render_pop(Particle particle);
void render_bubble(Bubble bubble);

void flush_entities(EntityRenderer *r);
void render_entity(EntityRenderer *restrict r, const void *restrict entity);
void flush_renderer(EntityType type);

void init_renderers(void);
void flush_renderers(void);

#endif
