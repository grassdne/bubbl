#version 330
precision highp float;

layout(location = 0) in vec2 vertpos;
layout(location = 1) in vec2 in_position;
layout(location = 2) in vec3 in_color;
layout(location = 3) in float in_radius;
layout(location = 4) in float in_age;
layout(location = 5) in int alive;

uniform vec2 resolution;
uniform float time;
uniform float starttime;

out vec2 pos;
out vec3 color;
out float radius;
out float age;

void main() {
    if (alive != 0) {
        // radius in [0, 2] scale
        vec2 radius_normalized = (in_radius * 4) / resolution * 2;
        // position [-1, 1] scale
        vec2 pos_normalized = in_position / resolution * 2.0 - 1;
        // pass in a square around the position
        gl_Position = vec4(vertpos * radius_normalized + pos_normalized, 0.0, 1.0);

        pos = in_position;
        color = in_color;
        radius = in_radius;
        age = in_age;
    }
    else {
        // Minor hack to simulate destroying pop without needing
        // to remove and shuffle down values from the buffer
        gl_Position = vec4(0.0,0.0,0.0,0.0);   
    }
}
