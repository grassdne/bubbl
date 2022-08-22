#include "bubbleshader.h"
#include "common.h"
#include "loader.h"

#include <stdio.h>
#include <stdlib.h>
#include <GLFW/glfw3.h>

#define MAX_BUBBLE_SPEED 500.0
#define BASE_RADIUS 30.0
#define VARY_RADIUS 30.0
#define MAX_COLLISION_FIX_TRIES 100
#define COLLISION_FIXUP_TIME 0.01


/*
 * Syntax:
 *
 * for ACTIVE_BUBBLES(i) {
 *    Bubble *bubble = &bubbles[i];
 *    ...
 * }
*/
#define ACTIVE_BUBBLES($) (int $ = 0; $ < sh->num_bubbles; ++$) if (sh->bubbles[$].alive)

#define UNI($name) sh->uniforms.$name = glGetUniformLocation(sh->program, #$name);
void get_program_vars(BubbleShader *sh)
{
    BUBBLE_UNIFORMS(UNI)
}
#undef UNI

// Explicitly numbered because need to match vertex shader
typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_BUBBLE_POS = 1,
    ATTRIB_BUBBLE_COLOR = 2,
    ATTRIB_BUBBLE_RADIUS = 3,
    ATTRIB_BUBBLE_ALIVE = 4,
} VertAttribLocs;

static struct { const char* file; const GLenum type; } shaderDatas[] = {
    { .file = "shaders/bubble_quad.vert", .type = GL_VERTEX_SHADER },
    { .file = "shaders/bubble.frag", .type = GL_FRAGMENT_SHADER },
};

static void pop_bubble(BubbleShader *sh, int i) {
    //TODO: animation!
    sh->bubbles[i].alive = false;
}

static float clamp(float v, float min, float max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
}

static double randreal(void) {
    return rand() / (double)RAND_MAX;
}

static void push_bubble(BubbleShader *sh, float x, float y) {
    Bubble *bubble;

    // Any dead bubbles to recycle?
    for (int i = 0; i < sh->num_bubbles; ++i) {
        if (!sh->bubbles[i].alive) {
            bubble = &sh->bubbles[i];
            goto found;
        }
    }
    // No dead bubbles, add a new one if there's room
    if (sh->num_bubbles + 1 >= BUBBLE_CAPACITY) return;
    bubble = &sh->bubbles[sh->num_bubbles++];
found:
    bubble->pos.x  = x;
    bubble->pos.y  = y;
    bubble->color.r  = randreal();
    bubble->color.g  = randreal();
    bubble->color.b  = randreal();
    // [BASE_RADIUS, BASE_RADIUS+VARY_RADIUS]
    bubble->rad = BASE_RADIUS + randreal() * VARY_RADIUS;
    // [-1, 1]
    bubble->d.x = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;
    // [-1, 1]
    bubble->d.y = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;
    bubble->alive = true;
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

static bool is_collision(BubbleShader *sh, int a, int b) {
    const float x = sh->bubbles[a].pos.x - sh->bubbles[b].pos.x;
    const float y = sh->bubbles[a].pos.y - sh->bubbles[b].pos.y;
    const float distSq = x*x + y*y;
    const float collisionDist = sh->bubbles[a].rad + sh->bubbles[b].rad;
    return distSq < collisionDist * collisionDist;
}

static void check_collisions(BubbleShader *sh) {
    for ACTIVE_BUBBLES(i) {
        for ACTIVE_BUBBLES(j) {
            if (j == i) continue; // Can't collide with yourself!
            if (is_collision(sh, i, j)) {

                Vector2 posDiff = vec_Sub(sh->bubbles[i].pos, sh->bubbles[j].pos);
                Vector2 norm = vec_Div(posDiff, vec_Length(posDiff));
                // v′1=v1−(n⋅(v1−v2))n
                Vector2 newV1 = vec_Sub(sh->bubbles[i].d,
                                        vec_Mult(norm,
                                                 vec_Dot(norm,
                                                         vec_Sub(sh->bubbles[i].d, sh->bubbles[j].d))));
                // v′2=v2−(n⋅(v2−v1))n
                Vector2 newV2 = vec_Sub(sh->bubbles[j].d,
                                        vec_Mult(norm,
                                                 vec_Dot(norm,
                                                         vec_Sub(sh->bubbles[j].d, sh->bubbles[i].d))));
                sh->bubbles[i].d = newV1;
                sh->bubbles[j].d = newV2;

                int try = 0;
                do {
                    update_position(sh, COLLISION_FIXUP_TIME, i);
                    update_position(sh, COLLISION_FIXUP_TIME, j);
                    if (try++ > MAX_COLLISION_FIX_TRIES) {
                        pop_bubble(sh, j);
                        break;
                    }
                } while (is_collision(sh, i, j));
            }
        }
    }
}

static void make_starting_bubbles(BubbleShader *sh) {
    const int W = window_width;
    const int H = window_height;
    push_bubble(sh, W * 0.25, H * 0.25);
    push_bubble(sh, W * 0.75, H * 0.25);
    push_bubble(sh, W * 0.25, H * 0.75);
    push_bubble(sh, W * 0.75, H * 0.75);
    push_bubble(sh, W * 0.50, H * 0.50);
}

#define BUBBLE_ATTRIB(loc, count, type, field) do{ \
    glEnableVertexAttribArray(loc); \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Bubble), (void*)offsetof(Bubble, field)); \
    glVertexAttribDivisor(loc, 1); }while(0)

static void init_bubble_vbo(BubbleShader *sh) {
    glGenBuffers(2, &sh->bubble_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->bubble_vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sh->bubbles), sh->bubbles, GL_DYNAMIC_DRAW);

    BUBBLE_ATTRIB(ATTRIB_BUBBLE_POS,    2, GL_FLOAT, pos);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_COLOR,  3, GL_FLOAT, color);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_RADIUS, 4, GL_FLOAT, rad);
    BUBBLE_ATTRIB(ATTRIB_BUBBLE_ALIVE,  1, GL_BYTE, alive);
}
#undef BUBBLE_ATTRIIB

static void build_shaders(BubbleShader *sh) {

    for (size_t i = 0; i < STATIC_LEN(shaderDatas); ++i) {
        //printf("Loading shader (type %s)\n", shaderTypeCStr(shaderDatas[i].type));
        const char* src = mallocShaderSource(shaderDatas[i].file); 
        GLuint shader = loadShader(shaderDatas[i].type, src, shaderDatas[i].file);

        free((void*)src);
        if (!shader) exit(1);

        glAttachShader(sh->program, shader);
    }
}

static void link_program(BubbleShader *sh) {
	glLinkProgram(sh->program);

	GLint linked = 0;
	glGetProgramiv(sh->program, GL_LINK_STATUS, &linked);
	if (!linked) {
		GLchar error_msg[GL_INFO_LOG_LENGTH];
		glGetProgramInfoLog(sh->program, GL_INFO_LOG_LENGTH, NULL, error_msg);
		fprintf(stderr, "Error linking program: %s", error_msg);
		glDeleteProgram(sh->program);
		exit(EXIT_FAILURE);
	}


	return;
}


static void initShaderProgram(BubbleShader *sh) {
	sh->program = glCreateProgram();
    build_shaders(sh);
    link_program(sh);
    get_program_vars(sh);
}

void bubbleOnMouseDown(BubbleShader *sh, Vector2 mouse)
{

    bool popped_bubble = false;
    // Destroy any bubbles under cursor
    for ACTIVE_BUBBLES(i) {
        if (sh->bubbles[i].alive && vec_Distance(sh->bubbles[i].pos, mouse) < sh->bubbles[i].rad) {
            pop_bubble(sh, i);
            popped_bubble = true;
        }
    }
    // Otherwise we create a new bubble
    if (!popped_bubble) push_bubble(sh, mouse.x, mouse.y);
}



void bubbleInit(BubbleShader *sh) {
	GLuint vertex_positions;
	glGenVertexArrays(1, &vertex_positions);
    glBindVertexArray(vertex_positions);

    glGenBuffers(1, &vertex_positions);
	glBindBuffer(GL_ARRAY_BUFFER, vertex_positions);
	glBufferData(GL_ARRAY_BUFFER, sizeof(QUAD), QUAD, GL_STATIC_DRAW);

    glEnableVertexAttribArray(ATTRIB_VERT_POS);
    glVertexAttribPointer(ATTRIB_VERT_POS, 2, GL_FLOAT, GL_FALSE, 0, NULL);

    init_bubble_vbo(sh);

    make_starting_bubbles(sh);
    initShaderProgram(sh);

}

void bubbleOnDraw(BubbleShader *sh, double dt) {
	glUseProgram(sh->program);

    // Update state
    for ACTIVE_BUBBLES(i) {
        update_position(sh, dt, i);
    }
    check_collisions(sh);
    
    // Update buffer
    glBindBuffer(GL_ARRAY_BUFFER, sh->bubble_vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(sh->bubbles), sh->bubbles);

    // Set uniforms
    glUniform1f(sh->uniforms.time, glfwGetTime());
    glUniform2f(sh->uniforms.resolution, window_width, window_height);

    // Draw
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, sh->num_bubbles);
}

