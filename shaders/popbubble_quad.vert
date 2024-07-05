#version 330

layout(location = 0) in vec4 vertpos;
layout(location = 2) in vec4 in_color;
layout(location = 9) in mat4 transform;

uniform vec2 resolution;
uniform float time;
uniform float starttime;

out vec2 local_coord;
out vec4 color;

void main() {
    gl_Position = transform * vertpos;

    color = in_color;
    local_coord = vertpos.xy;
}
