#version 330

layout(location = 0) in vec4 vertex_pos;

uniform vec2 resolution;
uniform float time;

layout(location = 1) in vec4 in_color_a;
layout(location = 9) in mat4 transform;

out vec4 color_a;
out vec2 local_coord;

void main() {
    gl_Position = transform * vertex_pos;

    color_a = in_color_a;
    local_coord = vertex_pos.xy;
}
