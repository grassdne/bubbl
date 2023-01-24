#include "bubbleshader.h"
#include "common.h"

#include <assert.h>
#include <stdlib.h>
#include <GLFW/glfw3.h>

const ShaderDatas BUBBLE_SHADER_DATAS = {
    .vert = "shaders/bubble_quad.vert",
    .frag = "shaders/bubble.frag",
};

// Need to match vertex shader layout
typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_BUBBLE_POS = 1,
    ATTRIB_COLOR_A = 2,
    ATTRIB_COLOR_B = 5,
    ATTRIB_BUBBLE_RADIUS = 3,
    ATTRIB_TRANS_ANGLE = 4,
    ATTRIB_TRANS_PERCENT = 6,
} AttributeLocations;

Bubble *get_bubble(BubbleShader *sh, size_t id)
{
    if (id < sh->num_bubbles+1) {
        Bubble *bubble = &sh->bubbles[id];
        return bubble;
    }
    return NULL;
}
void render_bubble(BubbleShader *sh, Bubble bubble)
{
    assert(sh->num_bubbles < BUBBLE_CAPACITY && "more bubbles than capacity");
    sh->bubbles[sh->num_bubbles++] = bubble;
}

void bubbleInit(BubbleShader *sh) {
    shaderBuildProgram(sh, BUBBLE_SHADER_DATAS, BUBBLE_UNIFORMS);
    BUBBLE_UNIFORMS(UNI_GETS);

    glBindVertexArray(sh->shader.vao);
    glGenBuffers(1, &sh->bubble_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->bubble_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sh->bubbles), sh->bubbles, GL_DYNAMIC_DRAW);

#define BUBBLE_ATTRIB(loc, count, type, field) do{ \
    glEnableVertexAttribArray(loc); \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Bubble), \
                          (void*)offsetof(Bubble, field)); \
    glVertexAttribDivisor(loc, 1); }while(0)

    BUBBLE_ATTRIB(ATTRIB_BUBBLE_POS, 2, GL_FLOAT, pos);
    BUBBLE_ATTRIB(ATTRIB_COLOR_A, 3, GL_FLOAT, color_a);
    BUBBLE_ATTRIB(ATTRIB_COLOR_B, 3, GL_FLOAT, color_b);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_RADIUS, 4, GL_FLOAT, rad);
    BUBBLE_ATTRIB(ATTRIB_TRANS_ANGLE, 2, GL_FLOAT, trans_angle);
    BUBBLE_ATTRIB(ATTRIB_TRANS_PERCENT, 1, GL_FLOAT, trans_percent);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

void flush_bubbles(BubbleShader *sh) {
    const double time = get_time();

    // Bind
	glUseProgram(sh->shader.program);
    glBindVertexArray(sh->shader.vao);
    glBindBuffer(GL_ARRAY_BUFFER, sh->bubble_vbo);
    // Update buffer
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(sh->bubbles), sh->bubbles);

    // Set uniforms
    glUniform1f(sh->uniforms.time, time);
    glUniform2f(sh->uniforms.resolution, window_width, window_height);

    // Draw
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->num_bubbles);

    // Unbind
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    sh->num_bubbles = 0;
}
