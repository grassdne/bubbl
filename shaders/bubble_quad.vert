#version 330

layout(location = 0) in vec2 vertpos;

layout(location = 1) in vec2 in_bubble;
layout(location = 2) in vec3 in_color;
layout(location = 3) in float in_radius;
layout(location = 4) in vec2 in_trans_angle;
layout(location = 5) in vec3 in_trans_color;
layout(location = 6) in float in_trans_percent;

out vec2 bubble_pos;
out vec3 bubble_color;
out float rad;
out vec2 trans_angle;
out vec3 trans_color;
out float trans_percent;

out float bottom_left_to_top_right;

uniform vec2 resolution;

#define TRANS_TIME 1.0

void main() {
    // radius in [0, 2] scale
    vec2 radius_normalized = in_radius / resolution * 2;
    // bubble position [-1, 1] scale
    vec2 bubblepos_normalized = in_bubble / resolution * 2.0 - 1;
    // pass in a square around the bubble position
    gl_Position = vec4(vertpos * radius_normalized + bubblepos_normalized, 0.0, 1.0);

    bubble_pos = in_bubble;
    bubble_color = in_color;
    rad = in_radius;
    bottom_left_to_top_right = length(resolution);
    trans_angle = in_trans_angle;
    trans_color = in_trans_color;
    trans_percent = in_trans_percent;
}
