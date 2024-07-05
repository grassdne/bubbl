/*
 * This is our "write-and-forget" OpenGL 'entity' renderer.
 * The rendering system has gone through many iterations
 * as I experiment and explore to finally come to this.
 * I believe it's a batch renderer.
 */

#include "entity_renderer.h"
#include "common.h"
#include "raymath.h"
#include "shaderutil.h"

#include <assert.h>
#include "SDL_video.h"

#define MATRIX_ATTR_LOCATION 9

void entity_init(EntityRenderer *r, const EntityRendererData data)
{
    shader_program_from_files(&r->shader, data.vert, data.frag);
    shader_vertices(&r->shader, data.geometry);
    r->uniforms.resolution = glGetUniformLocation(r->shader.program, "resolution");
    r->uniforms.time = glGetUniformLocation(r->shader.program, "time");

    r->num_entities = 0;
    r->entity_size = data.particle_size;

    // Create vertex buffer object

    r->buffer_size = ENTITIY_BUFFER_SIZE / data.particle_size;
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

    // Matrix attributes (takes up 4 locations)
    for (int i = 0; i < 4; i++) {
        int location = MATRIX_ATTR_LOCATION + i;
        glEnableVertexAttribArray(location);
        glVertexAttribPointer(location, 4, GL_FLOAT, GL_FALSE, data.particle_size, (void*)(i * sizeof(Vector4)));
        glVertexAttribDivisor(location, 1);
    }

}

void flush_entities(EntityRenderer *r)
{
    SDL_Window *window = SDL_GL_GetCurrentWindow();
    int w, h;
    SDL_GL_GetDrawableSize(window, &w, &h);

    /* Update vertex attributes for `vbo` */
    glBindBuffer(GL_ARRAY_BUFFER, r->vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, ENTITIY_BUFFER_SIZE, r->buffer);

    /* Update uniforms for program */
    glUseProgram(r->shader.program);
    glUniform2f(r->uniforms.resolution, w, h);
    glUniform1f(r->uniforms.time, get_time());

    run_shader_program(&r->shader, r->num_entities);
    
    /* Reset */
    r->num_entities = 0;
}

Matrix entity_projection(void) {
    return MatrixPerspective(0.5 * PI,
                             (float)drawing_width / (float)drawing_height,
                             0.1,
                             100.0);
}

Matrix entity_view(void) {
    Vector3 eye = { 0.0f, 0.0f, 1.0f };
    Vector3 target = { 0.0f, 0.0f, 0.0f };
    Vector3 up = { 0.0f, 1.0f, 0.0f };
    return MatrixLookAt(eye, target, up);
}

Matrix entity_transform(Matrix model) {
    Matrix transform = MatrixIdentity();
    transform = MatrixMultiply(transform, model);
    transform = MatrixMultiply(transform, entity_view());
    transform = MatrixMultiply(transform, entity_projection());
    return MatrixTranspose(transform);
}

void render_entity(EntityRenderer *restrict r, const void *restrict entity, Matrix model)
{
    Entity *_entity = (Entity*)entity;
    _entity->transform = entity_transform(model);
    // The size of the entity varies by the renderer
    // So we classically accept a void pointer and copy bytes

    if (r->num_entities >= r->buffer_size) {
        flush_entities(r);
    }
    void *top = &r->buffer[r->num_entities * r->entity_size];
    memcpy(top, entity, r->entity_size);
    r->num_entities += 1;
}
