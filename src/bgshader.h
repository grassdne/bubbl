#ifndef BG_SHADER_H
#define BG_SHADER_H

#include <GL/glew.h>
#include "common.h"
#include "shaderutil.h"

#define BG_UNIFORMS(_) _(positions) _(colors) _(num_elements) _(resolution)

typedef struct {
    Shader shader;
    struct {BG_UNIFORMS(UNI_DECL)} uniforms;
} BgShader;

void bgInit(BgShader *sh);

#endif
