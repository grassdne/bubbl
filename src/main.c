#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "common.h"
#include "loader.h"
#include "vector2.h"

#define SCREEN_WIDTH 1600
#define SCREEN_HEIGHT 900

#define BUBBLE_CAPACITY 100
#define MAX_BUBBLE_SPEED 400.0
#define BASE_RADIUS 30.0
#define VARY_RADIUS 30.0

#define UNIFORMS(_) _(time) _(resolution)

#define var(n) GLint n;
typedef struct {
    UNIFORMS(var)
} Uniforms;
#undef var

typedef struct {
    float r, g, b;
} Color;

typedef struct  {
    Vector2 pos;
    Color color;
    float rad;
    Vector2 d;
    GLbyte alive;
} Bubble;

Uniforms uniforms;

GLuint program;
bool playing = true;

Bubble bubbles[BUBBLE_CAPACITY] = {0}; // Initialize to zero
int num_bubbles = 0;
GLuint bubble_vbo;

int window_width = SCREEN_WIDTH;
int window_height = SCREEN_HEIGHT;

/*
 * Syntax:
 *
 * for ACTIVE_BUBBLES(i) {
 *    Bubble *bubble = &bubbles[i];
 *    ...
 * }
*/
#define ACTIVE_BUBBLES(it) (int it = 0; it < num_bubbles; ++it) if (bubbles[it].alive)

// Explicitly numbered because need to match vertex shader
typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_BUBBLE_POS = 1,
    ATTRIB_BUBBLE_COLOR = 2,
    ATTRIB_BUBBLE_RADIUS = 3,
    ATTRIB_BUBBLE_ALIVE = 4,
} VertAttribLocs;

void getProgramVars(void) {
#define UNI(name) uniforms.name = glGetUniformLocation(program, #name);
    UNIFORMS(UNI)
#undef UNI
}

static void error_callback(int error, const char* description) {
	(void)error;
	fputs(description, stderr);
}

static const char* shaderTypeCStr(GLenum shaderType) {
	switch (shaderType) {
	case GL_VERTEX_SHADER: return "Vertex";
	case GL_FRAGMENT_SHADER: return "Fragment";
	default: return "??";
	}
}

static GLuint loadShader(GLenum shaderType, const char* source, const char *from) {
	fflush(stdout);
	GLuint shader = glCreateShader(shaderType);
	glShaderSource(shader, 1, &source, NULL);
	glCompileShader(shader);

	GLint compiled = 0;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	if (!compiled) {
		GLchar error_msg[GL_INFO_LOG_LENGTH];
		glGetShaderInfoLog(shader, GL_INFO_LOG_LENGTH, NULL, error_msg);
		fprintf(stderr, "Error compiling shader (%s Shader) (in %s) %s\n", shaderTypeCStr(shaderType), from, error_msg);
		glDeleteShader(shader);
		return 0;
	}
	return shader;
}

static void linkProgram(void) {
	glLinkProgram(program);

	GLint linked = 0;
	glGetProgramiv(program, GL_LINK_STATUS, &linked);
	if (!linked) {
		GLchar error_msg[GL_INFO_LOG_LENGTH];
		glGetProgramInfoLog(program, GL_INFO_LOG_LENGTH, NULL, error_msg);
		fprintf(stderr, "Error linking program: %s", error_msg);
		glDeleteProgram(program);
		exit(EXIT_FAILURE);
	}

	glUseProgram(program);

	return;
}

static void buildShaders(void) {
    struct { const char* file; const GLenum type; } shaderDatas[] = {
        { .file = "shaders/bubble_quad.vert", .type = GL_VERTEX_SHADER },
        { .file = "shaders/bubble.frag", .type = GL_FRAGMENT_SHADER },
    };

    for (size_t i = 0; i < STATIC_LEN(shaderDatas); ++i) {
        //printf("Loading shader (type %s)\n", shaderTypeCStr(shaderDatas[i].type));
        const char* src = mallocShaderSource(shaderDatas[i].file); 
        GLuint shader = loadShader(shaderDatas[i].type, src, shaderDatas[i].file);

        free((void*)src);
        if (!shader) exit(1);

        glAttachShader(program, shader);
    }
}

static void initShaderProgram(void) {
	program = glCreateProgram();
    buildShaders();
    linkProgram();
    getProgramVars();
}

static double randreal() {
    return rand() / (double)RAND_MAX;
}

static void pop_bubble(int i) {
    //TODO: animation!
    bubbles[i].alive = false;
}

static void push_bubble(float x, float y) {
    int new;

    // Any dead bubbles to recycle?
    for (int i = 0; i < num_bubbles; ++i) {
        if (!bubbles[i].alive) {
            new = i;
            goto found;
        }
    }
    // No dead bubbles, add a new one if there's room
    new = num_bubbles++;
    if (new >= BUBBLE_CAPACITY) return;
found:
    bubbles[new].pos.x  = x;
    bubbles[new].pos.y  = y;
    bubbles[new].color.r  = randreal();
    bubbles[new].color.g  = randreal();
    bubbles[new].color.b  = randreal();
    // [BASE_RADIUS, BASE_RADIUS+VARY_RADIUS]
    bubbles[new].rad = BASE_RADIUS + randreal() * VARY_RADIUS;
    // [-1, 1]
    bubbles[new].d.x = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;
    // [-1, 1]
    bubbles[new].d.y = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;
    bubbles[new].alive = true;
}

static void on_mouse_down(GLFWwindow* window, int button, int action, int mods) {
    (void)mods;
    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        double xpos, ypos;
        int window_height;
        glfwGetCursorPos(window, &xpos, &ypos);	
        glfwGetWindowSize(window, NULL, &window_height);
        Vector2 mouse = {xpos, window_height - ypos};

        bool popped_bubble = false;
        // Destroy any bubbles under cursor
        for ACTIVE_BUBBLES(i) {
            if (bubbles[i].alive && vec_Distance(bubbles[i].pos, mouse) < bubbles[i].rad) {
                pop_bubble(i);
                popped_bubble = true;
            }
        }
        // Otherwise we create a new bubble
        if (!popped_bubble) push_bubble(mouse.x, mouse.y);
    }
}

static void on_window_resize(GLFWwindow *window, int width, int height) {
    (void)window;
    window_width = width;
    window_height = height;
    glViewport(0, 0, width, height);
}

static bool is_collision(int a, int b) {
    const float x = bubbles[a].pos.x - bubbles[b].pos.x;
    const float y = bubbles[a].pos.y - bubbles[b].pos.y;
    const float distSq = x*x + y*y;
    const float collisionDist = bubbles[a].rad + bubbles[b].rad;
    return distSq < collisionDist * collisionDist;
}

static float clamp(float v, float min, float max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
}

static void update_position(double dt, int i) {
    double nextx = bubbles[i].pos.x + bubbles[i].d.x * dt;
    const float rad = bubbles[i].rad;
    const float max_y = window_height - rad;
    const float max_x = window_width - rad;

    if (nextx < rad || nextx > max_x) {
        bubbles[i].d.x *= -1;
        nextx = clamp(bubbles[i].pos.x, rad, max_x);
    }
    bubbles[i].pos.x = nextx;
    double nexty = bubbles[i].pos.y + bubbles[i].d.y * dt;
    if (nexty < rad || nexty > max_y) {
        bubbles[i].d.y *= -1;
        nexty = clamp(bubbles[i].pos.y, rad, max_y);
    }
    bubbles[i].pos.y = nexty;
}

#define MAX_COLLISION_FIX_TRIES 100
#define COLLISION_FIXUP_TIME 0.01

static void check_collisions() {
    for ACTIVE_BUBBLES(i) {
        for ACTIVE_BUBBLES(j) {
            if (j == i) continue; // Can't collide with yourself!
            if (is_collision(i, j)) {

                Vector2 posDiff = vec_Sub(bubbles[i].pos, bubbles[j].pos);
                Vector2 norm = vec_Div(posDiff, vec_Length(posDiff));
                // v′1=v1−(n⋅(v1−v2))n
                Vector2 newV1 = vec_Sub(bubbles[i].d,
                                        vec_Mult(norm,
                                                 vec_Dot(norm,
                                                         vec_Sub(bubbles[i].d, bubbles[j].d))));
                // v′2=v2−(n⋅(v2−v1))n
                Vector2 newV2 = vec_Sub(bubbles[j].d,
                                        vec_Mult(norm,
                                                 vec_Dot(norm,
                                                         vec_Sub(bubbles[j].d, bubbles[i].d))));
                bubbles[i].d = newV1;
                bubbles[j].d = newV2;

                int try = 0;
                do {
                    update_position(COLLISION_FIXUP_TIME, i);
                    update_position(COLLISION_FIXUP_TIME, j);
                    if (try++ > MAX_COLLISION_FIX_TRIES) {
                        pop_bubble(j);
                        break;
                    }
                } while (is_collision(i, j));
            }
        }
    }
}

static void frame(GLFWwindow *window, double dt) {
    (void)window;
    glfwPollEvents();
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    for ACTIVE_BUBBLES(i) {
        update_position(dt, i);
    }

    check_collisions();
    glBindBuffer(GL_ARRAY_BUFFER, bubble_vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(bubbles), bubbles);

    glUniform1f(uniforms.time, glfwGetTime());
    glUniform2f(uniforms.resolution, window_width, window_height);

    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, num_bubbles);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	(void)scancode; (void)mods;
    if (action == GLFW_RELEASE) {
        switch (key) {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(window, GL_TRUE);
            break;
        }
    }
}

#define BUBBLE_ATTRIIB(loc, count, type, field) do{ \
    glEnableVertexAttribArray(loc); \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Bubble), (void*)offsetof(Bubble, field)); \
    glVertexAttribDivisor(loc, 1); }while(0)

static void create_bubble_buffer() {
    glGenBuffers(2, &bubble_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, bubble_vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(bubbles), bubbles, GL_DYNAMIC_DRAW);

    BUBBLE_ATTRIIB(ATTRIB_BUBBLE_POS,    2, GL_FLOAT, pos);
    BUBBLE_ATTRIIB(ATTRIB_BUBBLE_COLOR,  3, GL_FLOAT, color);
    BUBBLE_ATTRIIB(ATTRIB_BUBBLE_RADIUS, 4, GL_FLOAT, rad);
    BUBBLE_ATTRIIB(ATTRIB_BUBBLE_ALIVE,  1, GL_BYTE, alive);
}
#undef BUBBLE_ATTRIIB

void create_starting_bubbles() {
    const int W = SCREEN_WIDTH;
    const int H = SCREEN_HEIGHT;
    push_bubble(W * 0.25, H * 0.25);
    push_bubble(W * 0.75, H * 0.25);
    push_bubble(W * 0.25, H * 0.75);
    push_bubble(W * 0.75, H * 0.75);
    push_bubble(W * 0.50, H * 0.50);
}

int main()
{
	glfwSetErrorCallback(error_callback);
	if( !glfwInit()) exit(1);

	GLFWwindow* window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bubbles", NULL, NULL);
	if (!window) {
		glfwTerminate();
		exit(1);
	}

	glfwMakeContextCurrent(window);
	glfwSetKeyCallback(window, key_callback);
    glfwSetWindowSizeCallback(window, on_window_resize);

	if (glewInit() != GLEW_OK) {
		printf("GLEW init failed\n");
		abort();
	}
	else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
		printf("Shaders not available\n");
		abort();
	}

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    printf("OpenGL Version: %s\n", glGetString(GL_VERSION));

    glEnable(GL_DEPTH_TEST);

	float quad[] = { 1.0,  1.0, -1.0,  1.0, 1.0, -1.0, -1.0, -1.0 };

	GLuint vertex_positions;
	glGenVertexArrays(1, &vertex_positions);
    glBindVertexArray(vertex_positions);

    glGenBuffers(1, &vertex_positions);
	glBindBuffer(GL_ARRAY_BUFFER, vertex_positions);
	glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);

    glEnableVertexAttribArray(ATTRIB_VERT_POS);
    glVertexAttribPointer(ATTRIB_VERT_POS, 2, GL_FLOAT, GL_FALSE, 0, NULL);

    create_bubble_buffer();

    create_starting_bubbles();
    initShaderProgram();

    glfwSetMouseButtonCallback(window, on_mouse_down);

	//glfwSwapInterval(100);

    double time = glfwGetTime();
	while (!glfwWindowShouldClose(window)) {
        double now = glfwGetTime();
        double dt = now - time;
        time = now;

        frame(window, dt);
        if (playing) glfwSwapBuffers(window);
	}

	glfwDestroyWindow(window);
	glfwTerminate();
	exit(0);
}

