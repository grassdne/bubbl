#version 330
precision highp float;

layout(location = 0) in vec2 vertpos;
layout(location = 2) in vec4 in_color;
layout(location = 9) in mat4 transform;

uniform vec2 resolution;
uniform float time;
uniform float starttime;

out vec2 local_coord;
out vec4 color;

void main() {
    gl_Position = transform * vec4(vertpos, 0.0f, 1.0f);

    color = in_color;
    local_coord = vertpos.xy;
}
