#ifndef SHADER_UTIL_H
#define SHADER_UTIL_H
#include <GL/glew.h>

#define UNI_DECL($n) GLint $n;
#define UNI_GETS($name) sh->uniforms.$name = glGetUniformLocation(sh->shader.program, #$name);

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

#define shaderBuildProgram(sh, d, UNIFORMS) do{ \
    _shaderBuildProgram((Shader*)(sh), (d)); \
    UNIFORMS(UNI_GETS); \
}while(0)

void _shaderBuildProgram(Shader *sh, ShaderDatas d);

#endif
