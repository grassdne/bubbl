#version 330

layout(location = 0) in vec2 vertpos;

layout(location = 1) in vec2 in_bubble;
layout(location = 2) in vec3 in_color;
layout(location = 3) in float in_radius;
layout(location = 4) in int alive;

out vec2 bubble_pos;
out vec3 bubble_color;
out float rad;
out float bottom_left_to_top_right;

uniform vec2 resolution;
uniform bool is_foreground;


void main() {
    if (alive != 0) {
        if (is_foreground) {
            // radius in [0, 2] scale
            vec2 radius_normalized = in_radius / resolution * 2;
            // bubble position [-1, 1] scale
            vec2 bubblepos_normalized = in_bubble / resolution * 2.0 - 1;
            // pass in a square around the bubble position
            gl_Position = vec4(vertpos * radius_normalized + bubblepos_normalized, 0.0, 1.0);
        }
        else {
            gl_Position = vec4(vertpos, 0.0, 1.0);
        }

        bubble_pos = in_bubble;
        bubble_color = in_color;
        rad = in_radius;
        bottom_left_to_top_right = length(resolution);
    }
    else {
        // Minor hack to simulate destroying bubbles without needing
        // to remove and shuffle down values from the buffer
        gl_Position = vec4(0.0,0.0,0.0,0.0);   
    }
}
