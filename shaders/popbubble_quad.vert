#version 330

layout(location = 0) in vec4 vertex;
layout(location = 2) in vec4 in_color;
layout(location = 9) in mat4 transform;

out vec2 local_coord;
out vec4 color;

void main() {
    gl_Position = transform * vertex;

    color = in_color;
    local_coord = vertex.xy;
}
