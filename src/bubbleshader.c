#include "bubbleshader.h"
#include "common.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <GLFW/glfw3.h>

#define SETS_OF_BUBBLES 2
#define MAX_BUBBLE_SPEED 500.0
#define BASE_RADIUS 35.0
#define VARY_RADIUS 40.0
#define MAX_RADIUS (BASE_RADIUS + VARY_RADIUS)

#define GROWING_RDELTA 50.0
#define MAX_COLLISION_FIX_TRIES 100
#define COLLISION_FIXUP_TIME 0.01

// Bubble growing under mouse is at index 0
// I need everything in one big buffer for instanced rendering
#define GROWING_INDEX 0
#define GROWING() (sh->bubbles[GROWING_INDEX])

const ShaderDatas BUBBLE_SHADER_DATAS = {
    .vert = "shaders/bubble_quad.vert",
    .frag = "shaders/bubble.frag",
};


// main.c
void onRemoveBubble(Bubble*);

/*
 * Syntax:
 *
 * FOR_ACTIVE_BUBBLES(i) {
 *    Bubble *bubble = &bubbles[i];
 *    ...
 * }
*/
#define FOR_ACTIVE_BUBBLES($) for (int $ = GROWING_INDEX+1; $ <= sh->num_bubbles; ++$) if (sh->bubbles[$].alive)

// Explicitly numbered because need to match vertex shader
typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_BUBBLE_POS = 1,
    ATTRIB_BUBBLE_COLOR = 2,
    ATTRIB_BUBBLE_RADIUS = 3,
    ATTRIB_BUBBLE_ALIVE = 4,
} VertAttribLocs;

static void pop_bubble(Bubble *bubble) {
    bubble->alive = false;
    onRemoveBubble(bubble);
}

static float clamp(float v, float min, float max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
}

static double randreal(void) {
    return rand() / (double)RAND_MAX;
}

static void gen_random_speed(Bubble *bubble) {
    // [-1, 1]
    bubble->d.x = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;
    // [-1, 1]
    bubble->d.y = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;
}

static void new_bubble(Bubble *bubble, Vector2 pos, bool togrow) {
    bubble->pos = pos;
    bubble->color.r  = randreal();
    bubble->color.g  = randreal();
    bubble->color.b  = randreal();
    if (togrow) {
        bubble->rad = BASE_RADIUS;// + randreal() * VARY_RADIUS;
    } else {
        // [BASE_RADIUS, BASE_RADIUS+VARY_RADIUS]
        bubble->rad = BASE_RADIUS + randreal() * VARY_RADIUS;
    }
    gen_random_speed(bubble);
    bubble->alive = true;
}

int create_open_bubble_slot(BubbleShader *sh) {
    for (int i = 1; i < sh->num_bubbles; ++i) {
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

void bubbleCreate(BubbleShader *sh, Vector2 pos) {
    // Any dead bubbles to recycle?
    int slot = create_open_bubble_slot(sh);
    if (slot != -1) {
        new_bubble(&sh->bubbles[slot], pos, /*togrow = */false);
    }
}

static void update_position(BubbleShader *sh, double dt, int i) {
    double nextx = sh->bubbles[i].pos.x + sh->bubbles[i].d.x * dt;
    const float rad = sh->bubbles[i].rad;
    const float max_y = window_height - rad;
    const float max_x = window_width - rad;

    if (nextx < rad || nextx > max_x) {
        sh->bubbles[i].d.x *= -1;
        nextx = clamp(sh->bubbles[i].pos.x, rad, max_x);
    }
    sh->bubbles[i].pos.x = nextx;
    double nexty = sh->bubbles[i].pos.y + sh->bubbles[i].d.y * dt;
    if (nexty < rad || nexty > max_y) {
        sh->bubbles[i].d.y *= -1;
        nexty = clamp(sh->bubbles[i].pos.y, rad, max_y);
    }
    sh->bubbles[i].pos.y = nexty;
}

static bool is_collision(Bubble *a, Bubble *b) {
    const float x = a->pos.x - b->pos.x;
    const float y = a->pos.y - b->pos.y;
    const float distSq = x*x + y*y;
    const float collisionDist = a->rad + b->rad;
    return distSq < collisionDist * collisionDist;
}

static Vector2 elastic_collision_velocity(Vector2 dir, Vector2 other, Vector2 v) {
    return vec_Diff(v, vec_Mult(dir, vec_Dot(dir, vec_Diff(v, other))));
}

static void check_collisions(BubbleShader *sh) {
    FOR_ACTIVE_BUBBLES(i) {
        FOR_ACTIVE_BUBBLES(j) {
            if (j == i) continue; // Can't collide with yourself!
            if (is_collision(sh->bubbles+i, sh->bubbles+j)) {
                Vector2 dir = vec_Normalized(vec_Diff(sh->bubbles[i].pos, sh->bubbles[j].pos));

                Vector2 newV1 = elastic_collision_velocity(dir, sh->bubbles[j].d, sh->bubbles[i].d);
                Vector2 newV2 = elastic_collision_velocity(dir, sh->bubbles[i].d, sh->bubbles[j].d);

                sh->bubbles[i].d = newV1;
                sh->bubbles[j].d = newV2;

                float mindist = sh->bubbles[j].rad + sh->bubbles[i].rad + 1.0;
                sh->bubbles[i].pos = vec_Sum(sh->bubbles[j].pos, vec_Mult(dir, mindist));
            }
        }
    }

    // Special handling for bubble growing under cursor
    if (GROWING().alive) {
        FOR_ACTIVE_BUBBLES(i) if (is_collision(&GROWING(), &sh->bubbles[i])) {
            Vector2 dir = vec_Normalized(vec_Diff(sh->bubbles[i].pos, GROWING().pos));
            sh->bubbles[i].d = elastic_collision_velocity(dir, vec_Mult(vec_Neg(dir), 100), sh->bubbles[i].d);

            float mindist = GROWING().rad + sh->bubbles[i].rad + 1.0;
            sh->bubbles[i].pos = vec_Sum(GROWING().pos, vec_Mult(dir, mindist));
        }
    }
}

static void make_starting_bubbles(BubbleShader *sh) {
    const int W = window_width;
    const int H = window_height;
    for (int i = 0; i < SETS_OF_BUBBLES; ++i) {
        bubbleCreate(sh, (Vector2){ W * 0.25, H * 0.25 });
        bubbleCreate(sh, (Vector2){ W * 0.75, H * 0.25 });
        bubbleCreate(sh, (Vector2){ W * 0.25, H * 0.75 });
        bubbleCreate(sh, (Vector2){ W * 0.75, H * 0.75 });
        bubbleCreate(sh, (Vector2){ W * 0.50, H * 0.50 });
    }
}

#define BUBBLE_ATTRIB(loc, count, type, field) do{ \
    glEnableVertexAttribArray(loc); \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Bubble), (void*)offsetof(Bubble, field)); \
    glVertexAttribDivisor(loc, 1); }while(0)

static void init_bubble_vbo(BubbleShader *sh) {
    glGenBuffers(1, &sh->bubble_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->bubble_vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sh->bubbles), sh->bubbles, GL_DYNAMIC_DRAW);

    BUBBLE_ATTRIB(ATTRIB_BUBBLE_POS,    2, GL_FLOAT, pos);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_COLOR,  3, GL_FLOAT, color);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_RADIUS, 4, GL_FLOAT, rad);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_ALIVE,  1, GL_BYTE,  alive);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
}
#undef BUBBLE_ATTRIIB


int bubble_at_point(BubbleShader *sh, Vector2 mouse)
{
    FOR_ACTIVE_BUBBLES(i) {
        if (vec_Distance(sh->bubbles[i].pos, mouse) < sh->bubbles[i].rad) {
            return i;
        }
    }
    return -1;
}

void bubbleOnMouseDown(BubbleShader *sh, Vector2 mouse)
{
    int bubble = bubble_at_point(sh, mouse);
    // Pop the bubble the user clicked
    if (bubble != -1) {
        pop_bubble(sh->bubbles+bubble);
    }
    else {
        // Otherwise we create a new bubble
        new_bubble(&GROWING(), mouse, /*togrow = */true);
        GROWING().alive = true;
    }
}

void bubbleOnMouseUp(BubbleShader *sh, Vector2 mouse)
{
    (void)mouse;
    if (GROWING().alive) {
        int slot = create_open_bubble_slot(sh);
        if (slot >= 0) {
            sh->bubbles[slot] = GROWING();
        }
        GROWING().alive = false;
    }
}

void bubbleOnMouseMove(BubbleShader *sh, Vector2 mouse)
{
    if (GROWING().alive) {
        GROWING().pos = mouse;
    }
}

void bubbleInit(BubbleShader *sh) {
    GROWING().alive = false;

    shaderBuildProgram((Shader*)sh, BUBBLE_SHADER_DATAS, BUBBLE_UNIFORMS);

    make_starting_bubbles(sh);
    init_bubble_vbo(sh);
}

void bubbleOnDraw(BubbleShader *sh, double dt) {
    if (GROWING().alive) {
        GROWING().rad += GROWING_RDELTA * dt;
        if (GROWING().rad >= MAX_RADIUS) {
            pop_bubble(&GROWING());
            GROWING().alive = false;
        }
    }
    // Update state
    FOR_ACTIVE_BUBBLES(i) {
        update_position(sh, dt, i);
    }

    check_collisions(sh);

    // Bind
	glUseProgram(sh->program);
    glBindVertexArray(sh->vao);
    glBindBuffer(GL_ARRAY_BUFFER, sh->bubble_vbo);
    
    // Update buffer
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(sh->bubbles), sh->bubbles);

    /* Background */
    {
        // Set uniforms
        //glUniform1f(sh->uniforms.time, glfwGetTime());
        //glUniform2f(sh->uniforms.resolution, window_width, window_height);
        glUniform1i(sh->uniforms.is_foreground, GL_FALSE);

        // Draw
        glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->num_bubbles + 1);
    }

    /* Foreground */
    {
        // Set uniforms
        glUniform1f(sh->uniforms.time, glfwGetTime());
        glUniform2f(sh->uniforms.resolution, window_width, window_height);
        glUniform1i(sh->uniforms.is_foreground, GL_TRUE);

        // Draw
        glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->num_bubbles + 1);
    }

    // Unbind
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

