/**
 * A utility for building a shader program much more
 * conveniently.
*/

#ifndef SHADER_UTIL_H
#define SHADER_UTIL_H
#include "common.h"
#include <gl.h>

#define UNI_DECL(N) GLint N;
#define UNI_GETS(NAME) (sh)->uniforms.NAME = glGetUniformLocation((sh)->shader.program, #NAME);

#define CHECK_GL_ERROR() check_gl_error(__FILE__, __LINE__)

typedef struct { GLuint program; GLuint vao; } Shader;

void shader_program_from_files(Shader *sh, const char *vertex_filename, const char *fragment_filename);
void shader_program_from_source(Shader *shader, const char *id, const char *vertex_source, const char *fragment_source);
void run_shader_program(Shader *shader);
void use_shader_program(Shader *shader);
void shader_vertices(Shader *sh, const float *vertices, size_t size);
void shader_quad(Shader *sh);

#endif
