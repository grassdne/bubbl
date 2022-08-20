#version 330

layout(location = 0) in vec2 vertexPosition;

layout(location = 1) in vec2 in_bubble;
layout(location = 2) in vec3 in_color;
layout(location = 3) in float in_radius;

out vec2 bubble_pos;
out vec3 bubble_color;
out float rad;

void main() {
    gl_Position = vec4(vertexPosition, 0.0, 1.0);
    bubble_pos = in_bubble;
    bubble_color = in_color;
    rad = in_radius;
}
