#ifndef LOADER_H
#define LOADER_H
#include <GL/glew.h>

const char* mallocShaderSource(const char* fname);
GLuint loadShader(GLenum shaderType, const char* source, const char *from);

#endif
