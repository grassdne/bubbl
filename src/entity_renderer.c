#include "entity_renderer.h"
#include <stdio.h>
#include <assert.h>
#include <GLFW/glfw3.h>
#include <stdlib.h>

void entity_init(EntityRenderer *r, const EntityRendererData data)
{
    shaderBuildProgram(&r->shader, data.shaders, ENTITY_UNIFORMS);
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

    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

void flush_entities(EntityRenderer *r)
{
    /* Bind */
    glUseProgram(r->shader.program);
    glBindVertexArray(r->shader.vao);
    glBindBuffer(GL_ARRAY_BUFFER, r->vbo);

    /* Update */
    glBufferSubData(GL_ARRAY_BUFFER, 0, ENTITIY_BUFFER_SIZE, r->buffer);
    glUniform2f(r->uniforms.resolution, window_width, window_height);
    glUniform1f(r->uniforms.time, get_time());

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
