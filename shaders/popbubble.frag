#version 330

precision highp float;

layout(location = 0) out vec4 outcolor;

in vec2 pos;
// TODO: should color include alpha?
in vec3 color;
in float radius;
in float age;

const float LIFETIME = 1.0;
const float MIN_TRANSPARENCY = 0.2;


void main() {
    float dist = distance(gl_FragCoord.xy, pos);
    if (dist < radius) {
        float percent = age / LIFETIME;
        outcolor = vec4(color, mix(mix(1.0, MIN_TRANSPARENCY, dist / radius), 0, percent));
    }
    else {
        discard;
    }
}
