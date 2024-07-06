#version 330

layout(location=0) in vec2 pos;
uniform vec2 resolution;
out float LENGTH;

void main() {
    LENGTH = length(resolution);
    gl_Position = vec4(pos, 0.99, 1.0);
}
