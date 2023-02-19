#version 330

layout(location = 0) in vec2 vertpos;

layout(location = 1) in vec2 in_bubble;
layout(location = 2) in float in_radius;
layout(location = 3) in vec3 in_color_a;
layout(location = 4) in vec3 in_color_b;
layout(location = 5) in vec2 in_trans_angle;
layout(location = 6) in float in_trans_percent;

out vec2 bubble_pos;
out float rad;
out vec3 color_a;
out vec3 color_b;
out vec2 trans_angle;
out float trans_percent;

uniform vec2 resolution;

void main() {
    // radius in [0, 2] scale
    vec2 radius_normalized = in_radius / resolution * 2;
    // bubble position [-1, 1] scale
    vec2 bubblepos_normalized = in_bubble / resolution * 2.0 - 1;
    // pass in a square around the bubble position
    gl_Position = vec4(vertpos * radius_normalized + bubblepos_normalized, 0.0, 1.0);

    bubble_pos = in_bubble;
    rad = in_radius;
    color_a = in_color_a;
    color_b = in_color_b;
    trans_angle = in_trans_angle;
    trans_percent = in_trans_percent;
}
