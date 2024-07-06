#version 330

precision highp float;

layout(location = 0) out vec4 outcolor;

in vec4 color;
in vec2 local_coord;

const float MIN_TRANSPARENCY = 0.0;
const float ALPHA_DISCARD_THRESHOLD = 0.06;

void main() {
    float dist = distance(local_coord, vec2(0.0f));
    outcolor = vec4(color.rgb, mix(1.0, MIN_TRANSPARENCY, dist / 1.0f) * color.a);
}
