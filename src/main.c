#include <GL/glew.h>
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>

#define ERROR() strerror(errno)

const char* VS_SOURCE_FILE = "src/vertex.glsl";
const char* FS_SOURCE_FILE = "src/fragment.glsl";

static void error_callback(int error, const char* description) {
    (void)error;
    fputs(description, stderr);
}
static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    (void)scancode; (void)mods;
    if (key == GLFW_KEY_ESCAPE && action == GLFW_RELEASE) {
        glfwSetWindowShouldClose(window, GL_TRUE);
    }
}

static int min(int a, int b) {
    return a < b ? a : b;
}

static GLuint initBuffers(void) {
    GLuint positionBuffer;
    glCreateBuffers(1, &positionBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, positionBuffer);

    float positions[] = {
         1.f,  1.f,
        -1.f,  1.f,
         1.f, -1.f,
        -1.f, -1.f,
    };

    glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW);

    return positionBuffer;
}

static const char *shaderTypeCStr(GLenum shaderType) {
    switch (shaderType) {
    case GL_VERTEX_SHADER: return "Vertex";
    case GL_FRAGMENT_SHADER: return "Fragment";
    default: return "??";
    }
}

static GLuint loadShader(GLenum shaderType, const GLchar* source) {
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

static GLuint initShaderProgram(const GLchar* vsSource, const GLchar* fsSource) {
    GLuint vertShader, fragShader;
    if (!(vertShader = loadShader(GL_VERTEX_SHADER, vsSource))
     || !(fragShader = loadShader(GL_FRAGMENT_SHADER, fsSource)))
    {
        return 0;
    }

    GLuint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertShader);
    glAttachShader(shaderProgram, fragShader);
    glLinkProgram(shaderProgram);

    GLint linked = 0;
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLchar error_msg[GL_INFO_LOG_LENGTH];
        glGetProgramInfoLog(shaderProgram, GL_INFO_LOG_LENGTH, NULL, error_msg);
        fprintf(stderr, "Error linking program: %s", error_msg);
        glDeleteProgram(shaderProgram);
        return 0;
    }

    return shaderProgram;
}

static const char* mallocShaderSource(const char* fname) {
    FILE* f;
    if ((f = fopen(fname, "r")) == NULL) {
        fprintf(stderr, "File (%s): %s", fname, ERROR());
    }
    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *s = malloc(size);
    if ((fread(s, sizeof(char), size, f)) == 0) {
        fprintf(stderr, "File (%s): %s", fname, ERROR());
    }

    return s;
}

typedef struct {
    GLint vertexPosition;
} Attribs;

typedef struct {
    GLint pos;
    GLint time;
    GLint spinSpeed;
    GLint outerRadius;
} Uniforms;

Attribs attribs;
Uniforms uniforms;

static void onWindowResize(GLFWwindow *window, int width, int height) {
    glUniform2f(uniforms.pos, width / 2.f, height / 2.f);
    glUniform1f(uniforms.outerRadius, min(width, height) / 2.f - 50.);
    glfwSwapBuffers(window);
}

static void eventLoop(GLFWwindow* window) {
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        int width, height;
        glfwGetFramebufferSize(window, &width, &height);
        glViewport(0, 0, width, height);

        GLuint positionBuffer = initBuffers();

        glClearColor(1.f, 1.f, 1.f, 1.f);
        glClearDepth(1.f);
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glBindBuffer(GL_ARRAY_BUFFER, positionBuffer);
        glVertexAttribPointer(attribs.vertexPosition, 2, GL_FLOAT, GL_FALSE, 0, 0);
        glEnableVertexAttribArray(attribs.vertexPosition);

        glUniform1f(uniforms.time, glfwGetTime());

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        glEnd();
        glfwSwapBuffers(window);
    }
}

int main(void)
{
    GLFWwindow* window;
    glfwSetErrorCallback(error_callback);
    if (!glfwInit())
        exit(EXIT_FAILURE);
    window = glfwCreateWindow(640, 480, "OpenGL Testing", NULL, NULL);
    if (!window)
    {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    glfwMakeContextCurrent(window);
    glfwSetKeyCallback(window, key_callback);

    glClearColor(1.f, 1.f, 1.f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);

    if (glewInit() != GLEW_OK) {
       printf("GLEW init failed\n");
       abort();
    } else if (!GLEW_ARB_shading_language_100 || !GLEW_ARB_vertex_shader || !GLEW_ARB_fragment_shader || !GLEW_ARB_shader_objects) {
       printf("Shaders not available\n");
       abort();
    }

    const char* vsSource = mallocShaderSource(VS_SOURCE_FILE);
    const char* fsSource = mallocShaderSource(FS_SOURCE_FILE);

    GLuint program;
    if (!(program = initShaderProgram(vsSource, fsSource))) {
        fprintf(stderr, "Aborting.\n");
        exit(EXIT_FAILURE);
    }
    glUseProgram(program);

#define ATT(name) attribs.name = glGetAttribLocation(program, #name);
    ATT(vertexPosition);
#undef ATT

#define UNI(name) uniforms.name = glGetUniformLocation(program, #name);
    UNI(pos);
    UNI(time);
    UNI(spinSpeed);
    UNI(outerRadius);
#undef UNI
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

