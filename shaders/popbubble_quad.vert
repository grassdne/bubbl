#version 330
precision highp float;

layout(location = 0) in vec2 vertpos;
layout(location = 1) in vec2 offset;

uniform float age;
uniform vec2 position;
uniform vec3 color;

out vec2 pos;

void main() {
    gl_Position = vec4(vertpos, 0.0, 1.0);
    pos = position + offset;
}
