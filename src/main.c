#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>

#include <stddef.h>
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

#define UNIFORMS(_) _(time)

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
    float rad,
    r, g, b;
    Vector2 d;
} Bubble;

Uniforms uniforms;

GLuint program;
bool playing = true;

Bubble bubbles[BUBBLE_CAPACITY];
int num_bubbles = 0;
GLuint bubble_vbo;

// Explicitly numbered because need to match vertex shader
typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_BUBBLE_POS = 1,
    ATTRIB_BUBBLE_COLOR = 2,
    ATTRIB_BUBBLE_RADIUS = 3,
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

static GLuint loadShader(GLenum shaderType, const char* source) {
	fflush(stdout);
	GLuint shader = glCreateShader(shaderType);
	glShaderSource(shader, 1, &source, NULL);
	glCompileShader(shader);

	GLint compiled = 0;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	if (!compiled) {
		GLchar error_msg[GL_INFO_LOG_LENGTH];
		glGetShaderInfoLog(shader, GL_INFO_LOG_LENGTH, NULL, error_msg);
		fprintf(stderr, "Error compiling shader (%s Shader) %s\n", shaderTypeCStr(shaderType), error_msg);
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
        GLuint shader = loadShader(shaderDatas[i].type, src);

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

static void push_bubble(float x, float y) {
    if (num_bubbles >= BUBBLE_CAPACITY) return;
    Bubble *bubble = &bubbles[num_bubbles++];
    bubble->pos.x  = x;
    bubble->pos.y  = y;
    bubble->r  = randreal();
    bubble->g  = randreal();
    bubble->b  = randreal();
    // [BASE_RADIUS, BASE_RADIUS+VARY_RADIUS]
    bubble->rad = BASE_RADIUS + randreal() * VARY_RADIUS;
    // [-1, 1]
    bubble->d.x = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;
    // [-1, 1]
    bubble->d.y = (randreal() - 0.5) * 2 * MAX_BUBBLE_SPEED;

    glBindBuffer(GL_ARRAY_BUFFER, bubble_vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(bubbles), bubbles);
}

static void onMouseDown(GLFWwindow* window, int button, int action, int mods) {
    (void)mods;
    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        double xpos, ypos;
        int window_height;
        glfwGetCursorPos(window, &xpos, &ypos);	
        glfwGetWindowSize(window, NULL, &window_height);
        push_bubble(xpos, window_height - ypos);
    }
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
    const float max_y = SCREEN_HEIGHT - rad;
    const float max_x = SCREEN_WIDTH - rad;

    if (nextx < rad || nextx > max_x) {
        bubbles[i].d.x *= -1;
        nextx = clamp(bubbles[i].pos.x, rad, max_x);
    }
    bubbles[i].pos.x = nextx;
    //printf("dx: %f\n", bubbles[i].dx);
    double nexty = bubbles[i].pos.y + bubbles[i].d.y * dt;
    if (nexty < rad || nexty > max_y) {
        bubbles[i].d.y *= -1;
        nexty = clamp(bubbles[i].pos.y, rad, max_y);
    }
    bubbles[i].pos.y = nexty;
}

static void check_collisions() {
    for (int i = 0; i < num_bubbles; ++i) {
        for (int j = 0; j < num_bubbles; ++j) {
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

                do {
                    update_position(0.01, i);
                    update_position(0.01, j);
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

    for (int i = 0; i < num_bubbles; ++i) {
        update_position(dt, i);
    }

    check_collisions();
    glBindBuffer(GL_ARRAY_BUFFER, bubble_vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(bubbles), bubbles);

    glUniform1f(uniforms.time, glfwGetTime());

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

int main()
{
	GLFWwindow* window;
	glfwSetErrorCallback(error_callback);
	if (!glfwInit())
		exit(EXIT_FAILURE);
	window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bubbles", NULL, NULL);
	if (!window)
	{
		glfwTerminate();
		exit(EXIT_FAILURE);
	}
	glfwMakeContextCurrent(window);
	glfwSetKeyCallback(window, key_callback);

	if (glewInit() != GLEW_OK) {
		printf("GLEW init failed\n");
		abort();
	}
	else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
		printf("Shaders not available\n");
		abort();
	}

    glEnable(GL_DEPTH_TEST);

	float vertices[] = {
		 1.0,  1.0,
		-1.0,  1.0,
		 1.0, -1.0,
		-1.0, -1.0,
	};

	GLuint vertex_positions;
	glGenVertexArrays(1, &vertex_positions);
    glBindVertexArray(vertex_positions);

    glGenBuffers(1, &vertex_positions);
	glBindBuffer(GL_ARRAY_BUFFER, vertex_positions);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glEnableVertexAttribArray(ATTRIB_VERT_POS);
    glVertexAttribPointer(ATTRIB_VERT_POS, 2, GL_FLOAT, GL_FALSE, 0, NULL);

    glGenBuffers(1, &bubble_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, bubble_vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(bubbles), bubbles, GL_DYNAMIC_DRAW);

    // Bubble positions
    glEnableVertexAttribArray(ATTRIB_BUBBLE_POS);
    glVertexAttribPointer(ATTRIB_BUBBLE_POS, 2, GL_FLOAT, GL_FALSE, sizeof(Bubble), (void*)offsetof(Bubble, pos));
    glVertexAttribDivisor(ATTRIB_BUBBLE_POS, 1);

    // Bubble colors
    glEnableVertexAttribArray(ATTRIB_BUBBLE_COLOR);
    glVertexAttribPointer(ATTRIB_BUBBLE_COLOR, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Bubble), (void*) offsetof(Bubble, r));
    glVertexAttribDivisor(ATTRIB_BUBBLE_COLOR, 1);

    // Bubble radi
    glEnableVertexAttribArray(ATTRIB_BUBBLE_RADIUS);
    glVertexAttribPointer(ATTRIB_BUBBLE_RADIUS, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Bubble), (void*) offsetof(Bubble, rad));
    glVertexAttribDivisor(ATTRIB_BUBBLE_RADIUS, 1);

	glBindBuffer(GL_ARRAY_BUFFER, 0);

    {
        const int W = SCREEN_WIDTH;
        const int H = SCREEN_HEIGHT;
        push_bubble(W * 0.25, H * 0.25);
        push_bubble(W * 0.75, H * 0.25);
        push_bubble(W * 0.25, H * 0.75);
        push_bubble(W * 0.75, H * 0.75);
        push_bubble(W * 0.50, H * 0.50);
    }

    initShaderProgram();

    printf("OpenGL Version: %s\n", glGetString(GL_VERSION));

    glfwSetMouseButtonCallback(window, onMouseDown);

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
	exit(EXIT_SUCCESS);
}

