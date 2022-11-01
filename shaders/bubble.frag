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

void main() {
    float dist = distance(gl_FragCoord.xy, bubble_pos);
    if (dist < rad) {
        float a = mix(MIN_TRANSPARENCY, MAX_TRANSPARENCY, dist / rad);
        outcolor = vec4(bubble_color, a);
    }
    else { discard; }
}

