#version 330

layout(location = 0) out vec4 outcolor;

uniform vec2 resolution;
uniform float time;

in float rad;
in vec2 bubble_pos;
in vec3 bubble_color;
in float bottom_left_to_top_right;
in vec2 trans_angle;
in vec3 trans_color;
in float trans_starttime;

const float MIN_TRANSPARENCY = 0.0;
const float MAX_TRANSPARENCY = 0.7;

const float PI = 3.14159265358979;
const float LIGHT_REVOLUTION_TIME = 5.0;
const float BUBBLE_LIGHT_RAD = 0.2;
#define TRANS_TIME 1.0

float distanceSq(vec2 a, vec2 b) {
    vec2 diff =  a - b;
    return dot(diff, diff);
}

void main() {
    // Using squared distance to optimize out unneeded square root operation
    if (distanceSq(gl_FragCoord.xy, bubble_pos) < rad*rad) {
        float theta = time * 2*PI / LIGHT_REVOLUTION_TIME;
        vec2 light_pos = bubble_pos + rad*BUBBLE_LIGHT_RAD * vec2(cos(theta), sin(theta));
        // Color is gradiant between transitioning colors
        float percent_trans = (time - trans_starttime) / TRANS_TIME; 
        vec3 color = mix(trans_color, bubble_color,
            smoothstep(percent_trans * rad*2, (1+percent_trans)*rad*2, distance(gl_FragCoord.xy, bubble_pos + trans_angle*rad)));
        // Alpha is gradiant based on proximity to light center
        float a = mix(MIN_TRANSPARENCY, MAX_TRANSPARENCY, distance(gl_FragCoord.xy, light_pos) / rad);
        outcolor = vec4(color, a);
    }
    else { discard; }
}

