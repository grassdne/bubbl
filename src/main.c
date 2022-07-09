#include <stddef.h>
#define _CRT_SECURE_NO_WARNINGS
#include <GL/glew.h>
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>
#include <stdlib.h>
#include <stdio.h>
#include "common.h"
#include "loader.h"

typedef struct {
	GLint vertexPosition;
} Attribs;

#define UNIFORMS(_) _(pos) _(time) _(spinSpeed) _(outerRadius)

#define var(n) GLint n;
typedef struct {
    UNIFORMS(var)
} Uniforms;
#undef var

// globals
// make programInfo struct?
Attribs attribs;
Uniforms uniforms;
GLuint program;
bool playing = true;
double time;

void getProgramVars(void) {
#define ATT(name) attribs.name = glGetAttribLocation(program, #name);
#define UNI(name) uniforms.name = glGetUniformLocation(program, #name);
	ATT(vertexPosition);

    UNIFORMS(UNI)
#undef ATT
#undef UNI
}

static void error_callback(int error, const char* description) {
	(void)error;
	fputs(description, stderr);
}

static GLuint initBuffers(void) {
	GLuint positionBuffer;
	glCreateBuffers(1, &positionBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, positionBuffer);

	float positions[] = {
		 1.0,  1.0,
		-1.0,  1.0,
		 1.0, -1.0,
		-1.0, -1.0,
	};

	glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW);

	return positionBuffer;
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
        { .file = "vertex.glsl", .type = GL_VERTEX_SHADER },
        { .file = "fragment.glsl", .type = GL_FRAGMENT_SHADER },
    };

    for (size_t i = 0; i < STATIC_LEN(shaderDatas); ++i) {
        //printf("Loading shader (type %s)\n", shaderTypeCStr(shaderDatas[i].type));
        const char* src = mallocShaderSource(shaderDatas[i].file); 
        GLuint shader = loadShader(shaderDatas[i].type, src);

        free((void*)src);
        if (!shader) exit(EXIT_FAILURE);

        glAttachShader(program, shader);
    }
}

static void initShaderProgram(void) {
	program = glCreateProgram();
    buildShaders();
    linkProgram();
    getProgramVars();
}

static void onWindowResize(GLFWwindow* window, int width, int height) {
    (void)window;
	glUniform2f(uniforms.pos, width / 2.0, height / 2.0);
	glUniform1f(uniforms.outerRadius, MIN(width, height) / 2.0 - 100.);
	//glfwSwapBuffers(window);
}

static void frame(GLFWwindow *window) {
    glfwPollEvents();
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    glViewport(0, 0, width, height);

    GLuint positionBuffer = initBuffers();

    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClearDepth(1.0);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBindBuffer(GL_ARRAY_BUFFER, positionBuffer);
    glVertexAttribPointer(attribs.vertexPosition, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(attribs.vertexPosition);

    glUniform1f(uniforms.time, glfwGetTime());

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glEnd();
}

static void eventLoop(GLFWwindow* window) {
	while (!glfwWindowShouldClose(window)) {
        frame(window);
        if (playing) glfwSwapBuffers(window);
	}
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	(void)scancode; (void)mods;
    if (action == GLFW_RELEASE) {
        switch (key) {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(window, GL_TRUE);
            break;
        }
    } else {
        switch (key) {
        case GLFW_KEY_R: {
            glDeleteProgram(program);

            initShaderProgram();

            int winW, winH;
            glfwGetWindowSize(window, &winW, &winH);
            onWindowResize(window, winW, winH);
            break;
        }
        case GLFW_KEY_SPACE:
            playing = !playing;
            time = glfwGetTime();
            break;
        case GLFW_KEY_F:
            if (!playing) {
                glfwSetTime(time);
                frame(window);
                glfwSwapBuffers(window);
                time += 0.1;
            }
            break;
        case GLFW_KEY_B:
            if (!playing) {
                glfwSetTime(time);
                frame(window);
                glfwSwapBuffers(window);
                time -= 0.1;
                if (time < 0) time = 0;
            }
            break;
        }
    }
}

int main(void)
{
	GLFWwindow* window;
	glfwSetErrorCallback(error_callback);
	if (!glfwInit())
		exit(EXIT_FAILURE);
	window = glfwCreateWindow(640, 480, "Graphics Fun", NULL, NULL);
	if (!window)
	{
		glfwTerminate();
		exit(EXIT_FAILURE);
	}
	glfwMakeContextCurrent(window);
	glfwSetKeyCallback(window, key_callback);

	glClearColor(1.0, 1.0, 1.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);

	if (glewInit() != GLEW_OK) {
		printf("GLEW init failed\n");
		abort();
	}
	else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
		printf("Shaders not available\n");
		abort();
	}

    initShaderProgram();

	int winW, winH;
	glfwGetWindowSize(window, &winW, &winH);
	onWindowResize(window, winW, winH);
	glfwSetWindowSizeCallback(window, onWindowResize);

	glfwSwapInterval(1);

	eventLoop(window);

	glfwDestroyWindow(window);
	glfwTerminate();
	exit(EXIT_SUCCESS);
}

