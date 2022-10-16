#ifndef SHADER_UTIL_H
#define SHADER_UTIL_H
#include <GL/glew.h>

//const char* malloc_shader_source(const char* fname);
//GLuint loadShader(GLenum shaderType, const char* source, const char *from);

#define UNI_DECL($n) GLint $n;
#define UNI_GETS($name) sh->uniforms.$name = glGetUniformLocation(sh->program, #$name);

#define SHADER_PROGRAM_INHERIT() GLuint program; GLuint vao

typedef struct { SHADER_PROGRAM_INHERIT(); } Shader;

typedef struct {
    const char* vert;
    const char* frag;
} ShaderDatas;

void build_shaders(GLuint program, ShaderDatas shader_datas);
void bind_quad_vertex_array(void);
GLint get_bound_array_buffer(void);

void shaderInit(Shader *sh);
void shaderLinkProgram(Shader *sh);

#define shaderBuildProgram(sh, d, UNIFORMS) do{ \
    _shaderBuildProgram((Shader*)(sh), (d)); \
    UNIFORMS(UNI_GETS); \
}while(0)

void _shaderBuildProgram(Shader *sh, ShaderDatas d);

#endif
