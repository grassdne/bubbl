#version 330

layout(location = 0) out vec4 outcolor;

uniform float time;

in float rad;
in vec2 bubble_pos;
in vec3 bubble_color;

const float MIN_TRANSPARENCY = 0.1;

void main() {
    float dist = distance(gl_FragCoord.xy, bubble_pos);
    if (dist < rad) {
        outcolor = vec4(bubble_color, mix(1, MIN_TRANSPARENCY, dist / rad));
    } else {
        outcolor.a = 0.0;
    }
}

