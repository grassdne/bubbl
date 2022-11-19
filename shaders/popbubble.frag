#version 330

precision highp float;

layout(location = 0) out vec4 outcolor;

in vec2 pos;

uniform float age;
uniform vec3 color;
uniform float size;
uniform float particle_radius;

const float LIFETIME = 1.0;
const float MIN_TRANSPARENCY = 0.2;


void main() {
    float dist = distance(gl_FragCoord.xy, pos);
    if (dist < particle_radius) {
        float percent = age / LIFETIME;
        outcolor = vec4(color, mix(mix(1.0, MIN_TRANSPARENCY, dist / particle_radius), 0, percent));
    }
    else {
        discard;
    }
}
