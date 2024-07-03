#version 330

layout(location = 0) out vec4 outcolor;

uniform vec2 resolution;
uniform float time;

// TODO: should color_a and color_b accept alpha?

in vec4 color_a;
in vec2 local_coord;

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
    float rad = 1.0f;
    if (distanceSq(local_coord, vec2(0, 0)) < rad * rad) {
        // There is a little light spot inside the bubble
        // It orbits based on LIGHT_REVOLUTION_TIME
        float theta = time * 2*PI / LIGHT_REVOLUTION_TIME;
        vec2 light_pos = rad*BUBBLE_LIGHT_RAD * vec2(cos(theta), sin(theta));
        float dist_to_light_pos = distance(local_coord, light_pos);
        // Alpha is gradiant based on proximity to light center
        float a = mix(MIN_TRANSPARENCY, MAX_TRANSPARENCY, dist_to_light_pos / rad);
        outcolor = vec4(color_a.rgb, color_a.a * a);
    } else {
        //outcolor = vec4(0.0f, 0.0f, 0.0f, 1.0f);
    }
}
