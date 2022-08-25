#include "poppingshader.h"
#include "loader.h"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <GLFW/glfw3.h>

static struct { const char* file; const GLenum type; } shaderDatas[] = {
    { .file = "shaders/popbubble_quad.vert", .type = GL_VERTEX_SHADER },
    { .file = "shaders/popbubble.frag", .type = GL_FRAGMENT_SHADER },
};

typedef enum {
    ATTRIB_VERT_POS = 0,
    ATTRIB_PARTICLE_OFFSET = 1,
} VertAttribLocs;

#define POP_LIFETIME 1.0
#define EXPAND_MULT 2.0

#define LAYER_WIDTH 10.0
#define PARTICLE_LAYOUT 5
#define PT_RADIUS 5.0;
#define PT_DELTA_RADIUS (EXPAND_MULT / POP_LIFETIME)

//TODO: encapsulate
static void build_shaders(PoppingShader *sh) {
    for (size_t i = 0; i < STATIC_LEN(shaderDatas); ++i) {
        //printf("Loading shader (type %s)\n", shaderTypeCStr(shaderDatas[i].type));
        const char* src = mallocShaderSource(shaderDatas[i].file); 
        GLuint shader = loadShader(shaderDatas[i].type, src, shaderDatas[i].file);

        free((void*)src);
        if (!shader) exit(1);

        glAttachShader(sh->program, shader);
    }
}

//@encapsulate
static void link_program(PoppingShader *sh) {
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


	return;
}

#define UNI($name) sh->uniforms.$name = glGetUniformLocation(sh->program, #$name);
static void get_program_vars(PoppingShader *sh)
{
    POP_UNIFORMS(UNI);
}
#undef UNI

static void init_shader_program(PoppingShader *sh) {
	sh->program = glCreateProgram();
    build_shaders(sh);
    link_program(sh);
    get_program_vars(sh);
}


#define POPPING_ATTRIB(loc, count, type, field) do{ \
    glEnableVertexAttribArray(loc); \
    glVertexAttribPointer(loc, count, type, GL_FALSE, sizeof(Popping), (void*)offsetof(Popping, field)); \
    glVertexAttribDivisor(loc, 1); }while(0)

static void init_pop_vbo(PoppingShader *sh) {
    (void)sh;
    /*
    glGenBuffers(1, &sh->pop_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->pop_vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sh->pops), sh->pops, GL_DYNAMIC_DRAW);

    POPPING_ATTRIB(ATTRIB_POPPING,   1, GL_FLOAT, starttime);
    POPPING_ATTRIB(ATTRIB_POP_POS,   2, GL_FLOAT, pos);
    POPPING_ATTRIB(ATTRIB_POP_COLOR, 3, GL_FLOAT, color);
    POPPING_ATTRIB(ATTRIB_POP_SIZE,  1, GL_FLOAT, size);
    */
}
#undef BUBBLE_ATTRIIB


void poppingInit(PoppingShader *sh) {
    // TODO: encapsulate vertex array
    glGenBuffers(1, &sh->vertex_array);
	glBindBuffer(GL_ARRAY_BUFFER, sh->vertex_array);
	glBufferData(GL_ARRAY_BUFFER, sizeof(QUAD), QUAD, GL_STATIC_DRAW);

	glGenVertexArrays(1, &sh->vertex_array);
    glBindVertexArray(sh->vertex_array);

    glEnableVertexAttribArray(ATTRIB_VERT_POS);
    glVertexAttribPointer(ATTRIB_VERT_POS, 2, GL_FLOAT, GL_FALSE, 0, NULL);

    init_shader_program(sh);

    init_pop_vbo(sh);

    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

void poppingPop(PoppingShader *sh, Vector2 pos, Color color, float size)
{
    int n = -1;
    // Recycle dead pops
    for (int i = 0; i < sh->num_popping; ++i) {
        if (!sh->pops[i].alive) {
            n = i;
            break;
        }
    }
    // Is there room for another?
    if (n < 0 && sh->num_popping < (int)MAX_POPPING) {
        n = sh->num_popping++;
    }

    if (n < 0) {
        // We reached the limit!!
        return;
    }

    sh->pops[n].starttime = glfwGetTime();
    sh->pops[n].pos = pos;
    sh->pops[n].color = color;
    sh->pops[n].size = size;
    sh->pops[n].alive = true;
    sh->pops[n].pt_radius = PT_RADIUS;

    PopParticle *ps = sh->pops[n].particles;
    int i = 0;
    ps[i++] = (PopParticle) {
        .pos = vec_zero,
        .d = vec_zero,
    };
    for (float r = LAYER_WIDTH; r < size - LAYER_WIDTH; r += LAYER_WIDTH) {
        int numps = PARTICLE_LAYOUT * r / LAYER_WIDTH;
        for (int j = 0; j < numps; ++j) {
            float theta = 2.0*M_PI * ((float)j / numps);
            assert(i < MAX_PARTICLES);

            Vector2 rect = {cos(theta), sin(theta)};
            //printf("\t(%f, %f)\n", rect.x*r, rect.y*r);
            ps[i++] = (PopParticle) {
                .pos = vec_Mult(rect, r),
                .d   = vec_Mult(rect, EXPAND_MULT * r / POP_LIFETIME),
            };
        }
    }
    sh->pops[n].numparticles = i;

    glBindVertexArray(sh->vertex_array);

    glGenBuffers(1, &sh->pops[n].vbo);
	glBindBuffer(GL_ARRAY_BUFFER, sh->pops[n].vbo);
	glBufferData(GL_ARRAY_BUFFER, MAX_PARTICLES * sizeof(PopParticle), sh->pops[n].particles, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(ATTRIB_PARTICLE_OFFSET);
    // glVertexAttribPointer needs to be called on draw
    //glVertexAttribPointer(ATTRIB_PARTICLE_OFFSET, 2, GL_FLOAT, GL_FALSE, sizeof(PopParticle), (void*)0);
    glVertexAttribDivisor(ATTRIB_PARTICLE_OFFSET, 1);
}

void kill_popping(PoppingShader *sh, int i) {
    sh->pops[i].alive = false;
    glDeleteBuffers(1, &sh->pops[i].vbo);
}

void poppingOnDraw(PoppingShader *sh, double dt) {
    double time = glfwGetTime();

    for (int i = 0; i < sh->num_popping; ++i) {
        Popping *p = &sh->pops[i];
        if (!p->alive) continue;
        if (time - p->starttime > POP_LIFETIME) {
            kill_popping(sh, i);
            continue;
        }

        p->pt_radius += PT_DELTA_RADIUS * dt;
        for (int j = 0; j < p->numparticles; ++j) {
            p->particles[j].pos.x += p->particles[j].d.x * dt;
            p->particles[j].pos.y += p->particles[j].d.y * dt;
        }

        // Bind
        glUseProgram(sh->program);
        glBindVertexArray(sh->vertex_array);
        glBindBuffer(GL_ARRAY_BUFFER, p->vbo);
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(p->particles), p->particles);

        glVertexAttribPointer(ATTRIB_PARTICLE_OFFSET, 2, GL_FLOAT, GL_FALSE, sizeof(PopParticle), (void*)0);

        // Set uniforms
        glUniform1f(sh->uniforms.age, time - p->starttime);
        //printf("%d :: time: %f\n", i, time - p->starttime);
        glUniform2f(sh->uniforms.position, p->pos.x, p->pos.y);
        glUniform3f(sh->uniforms.color, p->color.r, p->color.g, p->color.b);
        glUniform1f(sh->uniforms.particle_radius, p->pt_radius);
        glUniform2f(sh->uniforms.resolution, window_width, window_height);

        // Draw
        glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, p->numparticles);
    }

    // Unbind
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}
