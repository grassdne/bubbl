#include "bg.h"
#include "shaderutil.h"
#include <stdio.h>

static Shader shader;

void bg_init(void) {
   shader_program_from_files(&shader, "shaders/blit.vert", "shaders/blit.frag"); 
}

int bg_create_texture(void *data, int width, int height)
{
    GLuint texture;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

    glBindTexture(GL_TEXTURE_2D, 0);
    
    return texture;
}

void bg_draw(GLuint texture, void *data, int width, int height) {
    glUseProgram(shader.program);
    glBindVertexArray(shader.vao);
    glBindTexture(GL_TEXTURE_2D, texture);

    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArray(0);
    glUseProgram(0);
}

#if 0
void bg_init(void) {
    glGenFramebuffers(1, &framebuffer);
}

void bg_draw(void *data, int width, int height) {
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
    GLuint texture;
    glGenTextures(1, &texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);

    printf ("blit!\n");
    printf("framebuffer=%d\n", framebuffer);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
    glBlitFramebuffer(0,0, width,height, 0,0, width,height, GL_COLOR_BUFFER_BIT, GL_LINEAR);

    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
}
#endif
