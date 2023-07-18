#version 330

precision highp float;

layout(location = 0) out vec4 outcolor;

in vec2 pos;
// TODO: should color include alpha?
in vec4 color;
in float radius;

const float MIN_TRANSPARENCY = 0.2;


void main() {
    float dist = distance(gl_FragCoord.xy, pos);
    if (dist < radius) {
        outcolor = vec4(color.rgb, mix(1.0, MIN_TRANSPARENCY, dist / radius) * color.a);
    }
    else {
        discard;
    }
}
