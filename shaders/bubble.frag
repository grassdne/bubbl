#version 330

layout(location = 0) out vec4 outcolor;

uniform float time;

in float rad;
in vec2 bubble_pos;
in vec3 bubble_color;

const vec3 background = vec3(1.0, 1.0, 1.0);
const float MIN_TRANSPARENCY = 0.2;

float sqDistance(vec2 a, vec2 b) {
    float x = a.x - b.x;
    float y = a.y - b.y;
    return x*x + y*y;
}

void main() {
    float dist = distance(gl_FragCoord.xy, bubble_pos);
    if (dist < rad) {
        outcolor = vec4(mix(bubble_color, background, max(MIN_TRANSPARENCY, dist / rad)), 1.0);
        gl_FragDepth = dist / rad;
    } else {
        gl_FragDepth = 1;
    }
}

