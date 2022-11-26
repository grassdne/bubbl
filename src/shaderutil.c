#include "shaderutil.h"
#include <stdlib.h>
#include "common.h"
#include <stdio.h>
#include <assert.h>

const char* malloc_file_source(const char* fpath) {
    FILE* f;
    if ((f = fopen(fpath, "r")) == NULL) {
        fprintf(stderr, "Unable to open file (%s): %s\n", fpath, ERROR());
        exit(1);
    }
    if (fseek(f, 0, SEEK_END)) {
        fprintf(stderr, "Unable to seek file (%s): %s\n", fpath, ERROR());
        exit(1);
    }
    size_t size = ftell(f);
    rewind(f);

    char* s = malloc(size + 1);
    if (s == NULL) {
        exit(1);
    }
    /* len != size with dos line endings
     * ftell counts \r\n as the correct 2 bytes,
     * but fread reads it in as just \n
     */
    size_t len = fread(s, 1, size, f);
    if (len == 0) {
        fprintf(stderr, "Unable to read file (%s): %s\n", fpath, ERROR());
        free(s);
        exit(1);
    }
    s[len] = '\0';

    return s;
}

static const char* shaderTypeCStr(GLenum shaderType) {
    switch (shaderType) {
    case GL_VERTEX_SHADER: return "Vertex";
    case GL_FRAGMENT_SHADER: return "Fragment";
    default: return "??";
    }
}


GLuint load_shader(GLenum shaderType, const char* source, const char *from) {
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

GLint get_bound_array_buffer(void) {
    GLint id;
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &id);
    return id;
}

void build_shader(GLuint program, const char *file, GLenum type) {
    const char* src = malloc_file_source(file); 
    GLuint shader = load_shader(type, src, file);
    free((void*)src);
    if (!shader) exit(1);

    glAttachShader(program, shader);
}

void build_shaders(GLuint prg, ShaderDatas shd) {
    // Required shaders
    assert(shd.vert);
    assert(shd.frag);
    build_shader(prg, shd.vert, GL_VERTEX_SHADER); 
    build_shader(prg, shd.frag, GL_FRAGMENT_SHADER); 
}

#define VERT_POS_ATTRIB_INDEX 0

const char* getGlErrMsg(GLenum err) {
    switch (err) {
        case GL_INVALID_ENUM: return "(GL_INVALID_ENUM) invalid argument for enumerated parameter";
        case GL_INVALID_VALUE: return "(GL_INVALID_VALUE) numeric argument out of range";
        case GL_INVALID_OPERATION: return "(GL_INVALID_OPERATION) operation is invalid";
        case GL_INVALID_FRAMEBUFFER_OPERATION: return "(GL_INVALID_FRAMEBUFFER_OPERATION) framebuffer object is not complete";
        case GL_OUT_OF_MEMORY: return "(GL_OUT_OF_MEMORY) ";
        default: return "no error recorded";
    }
}

#define CHECK_GL_ERROR() checkGlError(__FILE__, __LINE__)

void checkGlError(const char *file, const int line) {
    GLenum err = glGetError();
    if (err) {
        fprintf(stderr, "%s:%d: %s\n", file, line, getGlErrMsg(err));
        exit(1);
    }

}

void shaderInit(Shader *sh) {
    GLuint vbo; /* Don't need to hold on to this VBO name, it's in the VAO */
    // Gen
    glGenBuffers(1, &vbo);
    glGenVertexArrays(1, &sh->vao);

    // Bind
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBindVertexArray(sh->vao);

    glBufferData(GL_ARRAY_BUFFER, sizeof(QUAD), QUAD, GL_STATIC_DRAW);
    glVertexAttribPointer(VERT_POS_ATTRIB_INDEX, 2, GL_FLOAT, GL_FALSE, 0, (void*)0);
    glEnableVertexAttribArray(VERT_POS_ATTRIB_INDEX);

    // Cleanup
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    CHECK_GL_ERROR();
}

void shaderLinkProgram(Shader *sh) {
    glLinkProgram(sh->program);

    GLint linked = 0;
    glGetProgramiv(sh->program, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLchar error_msg[GL_INFO_LOG_LENGTH];
        glGetProgramInfoLog(sh->program, GL_INFO_LOG_LENGTH, NULL, error_msg);
        fprintf(stderr, "Error linking program: %s\n", error_msg);
        glDeleteProgram(sh->program);
        exit(1);
    }
}

void _shaderBuildProgram(Shader *sh, ShaderDatas shd) {
    shaderInit(sh);
    sh->program = glCreateProgram();
    build_shaders(sh->program, shd);
    shaderLinkProgram(sh);
}

double randreal(void) {
    return rand() / (double)RAND_MAX;
}

