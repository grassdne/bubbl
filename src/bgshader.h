#ifndef BG_SHADER_H
#define BG_SHADER_H

#include <GL/glew.h>
#include "common.h"
#include "shaderutil.h"
#include "bubbleshader.h"

#define BG_UNIFORMS(_) _(positions) _(colors) _(num_elements) _(resolution)

typedef struct {
    SHADER_PROGRAM_INHERIT();
    struct {BG_UNIFORMS(UNI_DECL)} uniforms;
    Bubble *bubbles;
    int    *numbbls;
} BgShader;

void bgInit(BgShader* restrict sh, Bubble *bubbles, int *numbbls);
void bgOnDraw(BgShader *sh, double dt);

#endif
