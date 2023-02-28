#ifndef SHADER_UTIL_H
#define SHADER_UTIL_H
#include <GL/glew.h>

#define UNI_DECL(N) GLint N;
#define UNI_GETS(NAME) (sh)->uniforms.NAME = glGetUniformLocation((sh)->shader.program, #NAME);

#define CHECK_GL_ERROR() checkGlError(__FILE__, __LINE__)
#undef glGenBuffers
#define glGenBuffers(...) __glewGenBuffers(__VA_ARGS__), CHECK_GL_ERROR()

typedef struct { GLuint program; GLuint vao; } Shader;

typedef struct {
    const char* vert;
    const char* frag;
} ShaderDatas;

void build_shaders(GLuint program, ShaderDatas shader_datas);
void bind_quad_vertex_array(void);
GLint get_bound_array_buffer(void);

void shaderInit(Shader *sh);
void shaderLinkProgram(Shader *sh);

void checkGlError(const char *file, const int line);

double randreal(void);

void shaderBuildProgram(Shader *sh, ShaderDatas d);

#endif
