#include "bubbleshader.h"
#include "common.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <GLFW/glfw3.h>

// Bubble growing under mouse is at index 0
// I need everything in one big buffer for instanced rendering
#define IN_TRANSITION(b) (!((b).trans_starttime == TRANS_STARTTIME_SENTINAL))
#define POST_COLLIDE_SPACING 1.0
#define TRANS_IMMUNE_PERIOD 1.0
#define TRANSITIONS_ENABLED 0

const ShaderDatas BUBBLE_SHADER_DATAS = {
    .vert = "shaders/bubble_quad.vert",
    .frag = "shaders/bubble.frag",
};

/*
 * Syntax:
 *
 * FOR_ACTIVE_BUBBLES(i) {
 *    Bubble *bubble = &bubbles[i];
 *    ...
 * }
*/

// Explicitly numbered because need to match vertex shader
typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_BUBBLE_POS = 1,
    ATTRIB_BUBBLE_COLOR = 2,
    ATTRIB_BUBBLE_RADIUS = 3,
    ATTRIB_BUBBLE_ALIVE = 4,
    ATTRIB_TRANS_ANGLE = 5,
    ATTRIB_TRANS_COLOR = 6,
    ATTRIB_TRANS_STARTTIME = 7,
} VertAttribLocs;

size_t create_open_bubble_slot(BubbleShader *sh)
{
    for (size_t i = 1; i < sh->num_bubbles; ++i) {
        if (!sh->bubbles[i].alive) {
            return i;
        }
    }

    // No dead bubbles, add a new one if there's room
    if (sh->num_bubbles + 1 < BUBBLE_CAPACITY) {
        return ++sh->num_bubbles;
    }

    return -1;
} 

void update_trans(Bubble *b, double time) {
    if (IN_TRANSITION(*b) && time - b->trans_starttime > TRANS_TIME)
    {
        b->color = b->trans_color;
        b->trans_starttime = TRANS_STARTTIME_SENTINAL;
        b->last_transformation = get_time();
    }
}

void start_transition(Bubble *restrict bubble, Bubble *restrict other) {
    bubble->trans_color = other->color;
    bubble->trans_starttime = get_time();
    bubble->trans_angle = vec_Normalized(vec_Diff(other->pos, bubble->pos));
}

#define BUBBLE_ATTRIB(loc, count, type, field) do{ \
    glEnableVertexAttribArray(loc); \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Bubble), \
                          (void*)offsetof(Bubble, field)); \
    glVertexAttribDivisor(loc, 1); }while(0)

static void init_bubble_vbo(BubbleShader *sh) {
    glGenBuffers(1, &sh->bubble_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->bubble_vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sh->bubbles), sh->bubbles, GL_DYNAMIC_DRAW);

    BUBBLE_ATTRIB(ATTRIB_BUBBLE_POS, 2, GL_FLOAT, pos);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_COLOR, 3, GL_FLOAT, color);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_RADIUS, 4, GL_FLOAT, rad);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_ALIVE, 1, GL_BYTE,  alive);
    BUBBLE_ATTRIB(ATTRIB_TRANS_ANGLE, 2, GL_FLOAT, trans_angle);
    BUBBLE_ATTRIB(ATTRIB_TRANS_COLOR, 3, GL_FLOAT, trans_color);
    BUBBLE_ATTRIB(ATTRIB_TRANS_STARTTIME, 1, GL_DOUBLE, trans_starttime);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
}
#undef BUBBLE_ATTRIIB


void destroy_bubble(BubbleShader *sh, size_t id) {
    sh->bubbles[id].alive = false;
}

Bubble *get_bubble(BubbleShader *sh, size_t id)
{
    if (id < sh->num_bubbles+1) {
        Bubble *bubble = &sh->bubbles[id];
        if (bubble->alive) {
            return bubble;
        }
    }
    return NULL;
}

int create_bubble(BubbleShader *sh, Color color, Vector2 position, Vector2 velocity, int radius)
{
    Bubble bubble = {
        .color = color,
        .pos = position,
        .v = velocity,
        .rad = radius,
        .trans_color = color,
        .trans_starttime = TRANS_STARTTIME_SENTINAL,
        .alive = true,
    };
    int slot = create_open_bubble_slot(sh);
    assert(slot >= 0 && "unable to create bubble");
    sh->bubbles[slot] = bubble;
    return slot;
}

void bubbleInit(BubbleShader *sh) {
    shaderBuildProgram(sh, BUBBLE_SHADER_DATAS, BUBBLE_UNIFORMS);
    init_bubble_vbo(sh);
}

void bubbleshader_draw(BubbleShader *sh) {
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
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->num_bubbles + 1);

    // Unbind
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

