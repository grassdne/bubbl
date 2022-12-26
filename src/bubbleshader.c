#include "bubbleshader.h"
#include "common.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <GLFW/glfw3.h>

#define DEFAULT_ENABLE_COLOR_SWAP_FUN true
#define SETS_OF_BUBBLES 1
#define MAX_BUBBLE_SPEED SCALECONTENT(350.0)
#define MIN_BUBBLE_SPEED SCALECONTENT(150.0)
#define BASE_RADIUS SCALECONTENT(35.0)
#define MAX_RADIUS SCALECONTENT(50.0)

#define MAX_GROWTH SCALECONTENT(200.0)
#define GROWTH_TIME 2.0
#define GROWING_RAD_DELTA (MAX_GROWTH / GROWTH_TIME)

// Bubble growing under mouse is at index 0
// I need everything in one big buffer for instanced rendering
#define GROWING_INDEX 0
#define GROWING() (sh->bubbles[GROWING_INDEX])
#define IN_TRANSITION(b) (!((b).trans_starttime == TRANS_STARTTIME_SENTINAL))
#define POST_COLLIDE_SPACING 1.0
#define TRANS_IMMUNE_PERIOD 1.0
#define TRANSITIONS_ENABLED 0

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
    ATTRIB_TRANS_ANGLE = 5,
    ATTRIB_TRANS_COLOR = 6,
    ATTRIB_TRANS_STARTTIME = 7,
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

static double randminmax(double min, double max) {
    return randreal() * (max - min) + min;
}

static double randomsign(void) {
    return randreal() > 0.5 ? -1.0 : 1.0;
}

static void gen_random_speed(Bubble *bubble) {
    bubble->v.x = randomsign() * randminmax(MIN_BUBBLE_SPEED, MAX_BUBBLE_SPEED);
    bubble->v.y = randomsign() * randminmax(MIN_BUBBLE_SPEED, MAX_BUBBLE_SPEED);
}

static void new_bubble(Bubble *bubble, Vector2 pos, bool togrow) {
    bubble->pos = pos;
    bubble->color.r  = randreal();
    bubble->color.g  = randreal();
    bubble->color.b  = randreal();
    bubble->trans_color = bubble->color;
    if (togrow) {
        bubble->rad = BASE_RADIUS;
    } else {
        // [BASE_RADIUS, BASE_RADIUS+VARY_RADIUS]
        bubble->rad = randminmax(BASE_RADIUS, MAX_RADIUS);
    }
    gen_random_speed(bubble);
    bubble->alive = true;
    bubble->trans_starttime = TRANS_STARTTIME_SENTINAL;
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
    if (sh->paused_movement || IN_TRANSITION(sh->bubbles[i]))
        return;

    double nextx = sh->bubbles[i].pos.x + sh->bubbles[i].v.x * dt;
    const float rad = sh->bubbles[i].rad;
    const float max_y = window_height - rad;
    const float max_x = window_width - rad;

    if (nextx < rad || nextx > max_x) {
        sh->bubbles[i].v.x *= -1;
        nextx = clamp(sh->bubbles[i].pos.x, rad, max_x);
    }
    sh->bubbles[i].pos.x = nextx;
    double nexty = sh->bubbles[i].pos.y + sh->bubbles[i].v.y * dt;
    if (nexty < rad || nexty > max_y) {
        sh->bubbles[i].v.y *= -1;
        nexty = clamp(sh->bubbles[i].pos.y, rad, max_y);
    }
    sh->bubbles[i].pos.y = nexty;
}

static void update_trans(Bubble *b, double time) {
    if (IN_TRANSITION(*b) && time - b->trans_starttime > TRANS_TIME)
    {
        b->color = b->trans_color;
        b->trans_starttime = TRANS_STARTTIME_SENTINAL;
        b->last_transformation = glfwGetTime();
    }
}

static bool is_collision(Bubble *restrict a, Bubble *restrict b) {
    const float x = a->pos.x - b->pos.x;
    const float y = a->pos.y - b->pos.y;
    const float distSq = x*x + y*y;
    const float collisionDist = a->rad + b->rad;
    return distSq < collisionDist * collisionDist;
}

static void separate_bubbles(Bubble *restrict a, Bubble *restrict b) {
    // Push back bubble a so it is no longer colliding with b
    Vector2 dir = vec_Normalized(vec_Diff(a->pos, b->pos));
    float mindist = b->rad + a->rad + POST_COLLIDE_SPACING;
    a->pos = vec_Sum(b->pos, vec_Mult(dir, mindist));
}

static void start_transition(Bubble *restrict bubble, Bubble *restrict other) {
    bubble->trans_color = other->color;
    bubble->trans_starttime = glfwGetTime();
    bubble->trans_angle = vec_Normalized(vec_Diff(other->pos, bubble->pos));
}

static void check_collisions(BubbleShader *sh) {
    FOR_ACTIVE_BUBBLES(i) {
        FOR_ACTIVE_BUBBLES(j) {
            if (j == i) continue; // Can't collide with yourself!
            if (is_collision(sh->bubbles+i, sh->bubbles+j)) {
                // Simple elastic collision
                // An elastic collision with the same masses means they just 
                // swap velocities!
                // TODO: Should they have different masses?
                Vector2 Vi = sh->bubbles[i].v;
                Vector2 Vj = sh->bubbles[j].v;
                sh->bubbles[i].v = Vj;
                sh->bubbles[j].v = Vi;

                separate_bubbles(&sh->bubbles[i], &sh->bubbles[j]);
                const double time = glfwGetTime();
                if (TRANSITIONS_ENABLED
                &&  !IN_TRANSITION(sh->bubbles[i])
                &&  !IN_TRANSITION(sh->bubbles[j])
                &&  time-sh->bubbles[i].last_transformation > TRANS_IMMUNE_PERIOD
                &&  time-sh->bubbles[j].last_transformation > TRANS_IMMUNE_PERIOD)
                {
                    start_transition(&sh->bubbles[i], &sh->bubbles[j]);
                    start_transition(&sh->bubbles[j], &sh->bubbles[i]);
                }
            }
        }
    }

    // Special physics for bubble growing under cursor
    if (GROWING().alive) {
        FOR_ACTIVE_BUBBLES(i) if (is_collision(&GROWING(), &sh->bubbles[i])) {
            sh->bubbles[i].v = vec_Neg(sh->bubbles[i].v);
            separate_bubbles(&sh->bubbles[i], &GROWING());
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

    shaderBuildProgram(sh, BUBBLE_SHADER_DATAS, BUBBLE_UNIFORMS);

    make_starting_bubbles(sh);
    init_bubble_vbo(sh);
}

void bubbleOnDraw(BubbleShader *sh, double dt) {
    if (GROWING().alive) {
        GROWING().rad += (GROWING_RAD_DELTA * dt);
        if (GROWING().rad >= MAX_GROWTH) {
            pop_bubble(&GROWING());
            GROWING().alive = false;
        }
    }
    const double time = glfwGetTime();

    // Update state
    FOR_ACTIVE_BUBBLES(i) {
        update_position(sh, dt, i);
        update_trans(&sh->bubbles[i], time);
    }

    check_collisions(sh);

    // Bind
	glUseProgram(sh->program);
    glBindVertexArray(sh->vao);
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

