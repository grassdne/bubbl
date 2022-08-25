#version 330
precision highp float;

layout(location = 0) in vec2 vertpos;
layout(location = 1) in vec2 offset;

uniform float age;
uniform vec2 position;
uniform vec3 color;
uniform float particle_radius;
uniform vec2 resolution;

out vec2 pos;

void main() {
    pos = position + offset;

    // radius in [0, 2] scale
    vec2 radius_normalized = particle_radius / resolution * 2;
    // position [-1, 1] scale
    vec2 pos_normalized = pos / resolution * 2.0 - 1;
    // pass in a square around the position
    gl_Position = vec4(vertpos * radius_normalized + pos_normalized, 0.0, 1.0);
}
