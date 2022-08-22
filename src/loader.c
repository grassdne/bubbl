#include "loader.h"
#include "common.h"
#include <stdlib.h>
#include <stdio.h>

const char* mallocShaderSource(const char* fpath) {
	FILE* f;
	if ((f = fopen(fpath, "r")) == NULL) {
		fprintf(stderr, "Unable to open file (%s): %s", fpath, ERROR());
		exit(1);
	}
	if (fseek(f, 0, SEEK_END)) {
        fprintf(stderr, "Unable to seek file (%s): %s", fpath, ERROR());
        exit(1);
    }
	size_t size = ftell(f);
    rewind(f);

	char* s = malloc(size + 1);
    if (s == NULL) {
        exit(1);
    }
	if ((fread(s, sizeof(char), size, f)) == 0) {
		fprintf(stderr, "Unable to read file (%s): %s", fpath, ERROR());
		exit(1);
	}
    fclose(f);
	s[size] = '\0';

	return s;
}

static const char* shaderTypeCStr(GLenum shaderType) {
	switch (shaderType) {
	case GL_VERTEX_SHADER: return "Vertex";
	case GL_FRAGMENT_SHADER: return "Fragment";
	default: return "??";
	}
}


GLuint loadShader(GLenum shaderType, const char* source, const char *from) {
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
