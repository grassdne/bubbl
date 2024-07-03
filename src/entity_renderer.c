/*
 * This is our "write-and-forget" OpenGL 'entity' renderer.
 * The rendering system has gone through many iterations
 * as I experiment and explore to finally come to this.
 * I believe it's a batch renderer.
 */

#include "entity_renderer.h"
#include "SDL_video.h"
#include "shaderutil.h"

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <raymath.h>

void entity_init(EntityRenderer *r, const EntityRendererData data)
{
    shader_program_from_files(&r->shader, data.vert, data.frag);
    r->uniforms.resolution = glGetUniformLocation(r->shader.program, "resolution");
    r->uniforms.time = glGetUniformLocation(r->shader.program, "time");
    r->uniforms.transform = glGetUniformLocation(r->shader.program, "transform");

    r->num_entities = 0;
    r->entity_size = data.particle_size;

    // Create vertex buffer object
    if (r->buffer_size > 0) {
        r->buffer_size = ENTITIY_BUFFER_SIZE / data.particle_size;
    } else {
        r->buffer_size = 0;
    }

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

Matrix gen_view() {
    Vector3 eye = { 0.0f, 0.0f, 1.0f };
    Vector3 target = { 0.0f, 0.0f, 0.0f };
    Vector3 up = { 0.0f, 1.0f, 0.0f };
    return MatrixLookAt(eye, target, up);
}

Matrix gen_projection() {
    return MatrixPerspective(0.5 * PI, 600.0/600.0, 0.1, 100.0);
}

Matrix gen_model() {
    /*Matrix model = MatrixTranslate();*/
    return MatrixIdentity();
    /*return MatrixRotate((Vector3) { 1.0f, 0.0f, 0.0f}, DEG2RAD * -45);*/
}

Matrix gen_transform() {
    return MatrixMultiply(MatrixMultiply(gen_model(), gen_view()), gen_projection());
}

void flush_entities(EntityRenderer *r)
{
    /* Bind */
    glUseProgram(r->shader.program);
    glBindVertexArray(r->shader.vao);
    glBindBuffer(GL_ARRAY_BUFFER, r->vbo);

    SDL_Window *window = SDL_GL_GetCurrentWindow();
    int w, h;
    SDL_GL_GetDrawableSize(window, &w, &h);

    /* Update */
    glBufferSubData(GL_ARRAY_BUFFER, 0, ENTITIY_BUFFER_SIZE, r->buffer);
    glUniform2f(r->uniforms.resolution, w, h);
    glUniform1f(r->uniforms.time, get_time());
    Matrix transform = gen_transform();
    static_assert(sizeof(transform) == 16 * sizeof(GLfloat), "Transform matrix should be packed!");
    glUniformMatrix4fv(r->uniforms.transform, 1, GL_TRUE, (const GLfloat*)&transform);

    /* Draw */
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, r->num_entities);
    
    /* Reset */
    r->num_entities = 0;
    glUseProgram(0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void render_entity(EntityRenderer *restrict r, const void *restrict entity)
{
    // The size of the entity varies by the renderer
    // So we classically accept a void pointer and copy bytes

    if (r->num_entities >= r->buffer_size) {
        flush_entities(r);
    }
    void *top = &r->buffer[r->num_entities * r->entity_size];
    memcpy(top, entity, r->entity_size);
    r->num_entities += 1;
}
