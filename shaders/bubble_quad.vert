#version 330

layout(location = 0) in vec2 vertpos;

layout(location = 1) in vec2 in_bubble;
layout(location = 2) in vec3 in_color;
layout(location = 3) in float in_radius;
layout(location = 4) in int alive;

out vec2 bubble_pos;
out vec3 bubble_color;
out float rad;

uniform vec2 resolution;


void main() {
    if (alive != 0) {
        // radius in [0, 2] scale
        vec2 radius_normalized = in_radius / resolution * 2;
        // bubble position [-1, 1] scale
        vec2 bubblepos_normalized = in_bubble / resolution * 2.0 - 1;
        // pass in a square around the bubble position
        gl_Position = vec4(vertpos * radius_normalized + bubblepos_normalized, 0.0, 1.0);

        bubble_pos = in_bubble;
        bubble_color = in_color;
        rad = in_radius;
    }
    else {
        // Minor hack to simulate destroying bubbles without needing
        // to remove and shuffle down values from the buffer
        gl_Position = vec4(0.0,0.0,0.0,0.0);   
    }
}
