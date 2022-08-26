#version 330

layout(location = 0) out vec4 outcolor;

uniform vec2 resolution;
uniform bool is_foreground;
uniform float time;

in float rad;
in vec2 bubble_pos;
in vec3 bubble_color;
in float bottom_left_to_top_right;

const float MIN_TRANSPARENCY = 0.0;
const float PI = 3.14159265358979323846264;

float interpolate_back_and_forth(float min, float max, float t) {
    return min + (cos(2*PI * t) + 1.0) / 2.0 * (max - min);
}

float lengthSq(vec2 vec) {
    return vec.x * vec.x + vec.y * vec.y;
}

const vec3 bg = vec3(1.0, 1.0, 1.0);

void main() {
    float outerrad;
    float dist = distance(gl_FragCoord.xy, bubble_pos);
    if (is_foreground) {
        if (dist < rad) {
            float a = mix(MIN_TRANSPARENCY, 0.7, dist / rad);
            outcolor = vec4(mix(bg, bubble_color, a), 1.0);
        }
        else {
            discard;
        }
    }
    else {
        outcolor.rgb = mix(bg, bubble_color, 0.4);
        outcolor.a = smoothstep(0.5, 0.0, dist / length(resolution));
    }
}

