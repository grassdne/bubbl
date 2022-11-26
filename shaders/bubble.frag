#version 330

layout(location = 0) out vec4 outcolor;

uniform vec2 resolution;
uniform float time;

in float rad;
in vec2 bubble_pos;
in vec3 bubble_color;
in float bottom_left_to_top_right;

const float MIN_TRANSPARENCY = 0.0;
const float MAX_TRANSPARENCY = 0.7;

const float PI = 3.14159265358979;
const float SHADOW_REVOLUTION_TIME = 5.0;
const float BUBBLE_SHADOW_RAD = 0.2;

float distanceSq(vec2 a, vec2 b) {
    vec2 diff =  a - b;
    return dot(diff, diff);
}

void main() {
    // Using squared distance to optimize out unneeded square root operation
    if (distanceSq(gl_FragCoord.xy, bubble_pos) < rad*rad) {
        float theta = time * 2*PI / SHADOW_REVOLUTION_TIME;
        vec2 shadow_pos = bubble_pos + rad*BUBBLE_SHADOW_RAD * vec2(cos(theta), sin(theta));
        float a = mix(MIN_TRANSPARENCY, MAX_TRANSPARENCY, distance(gl_FragCoord.xy, shadow_pos) / rad);
        outcolor = vec4(bubble_color, a);
    }
    else { discard; }
}

