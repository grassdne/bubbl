/*
 * This is our "write-and-forget" OpenGL 'entity' renderer.
 * The rendering system has gone through many iterations
 * as I experiment and explore to finally come to this.
 * I believe it's a batch renderer.
 */

#include "entity_renderer.h"
#include "shaderutil.h"

#include <assert.h>
#include "SDL_video.h"

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
