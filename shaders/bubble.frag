#version 330

layout(location = 0) out vec4 outcolor;

uniform vec2 resolution;
uniform float time;

// TODO: should color_a and color_b accept alpha?

in float rad;
in vec2 bubble_pos;
in vec4 color_a;

const float MIN_TRANSPARENCY = 0.0;
const float MAX_TRANSPARENCY = 0.7;

const float PI = 3.14159265358979;
const float LIGHT_REVOLUTION_TIME = 5.0;
const float BUBBLE_LIGHT_RAD = 0.2;
const float GRADIENT_WIDTH_MULTIPLIER = 1.0;

float distanceSq(vec2 a, vec2 b) {
    vec2 diff =  a - b;
    return dot(diff, diff);
}

void main() {
    // Comparing against squared distance to optimize out unneeded square root operation
    if (distanceSq(gl_FragCoord.xy, bubble_pos) < rad*rad) {
        // There is a little light spot inside the bubble
        // It orbits based on LIGHT_REVOLUTION_TIME
        float theta = time * 2*PI / LIGHT_REVOLUTION_TIME;
        vec2 light_pos = bubble_pos + rad*BUBBLE_LIGHT_RAD * vec2(cos(theta), sin(theta));
        float dist_to_light_pos = distance(gl_FragCoord.xy, light_pos);
        // Alpha is gradiant based on proximity to light center
        float a = mix(MIN_TRANSPARENCY, MAX_TRANSPARENCY, dist_to_light_pos / rad);
        outcolor = vec4(color_a.rgb, color_a.a * a);
    }
    else { discard; }
}

