#version 330

layout(location = 0) out vec4 outcolor;

uniform vec2 resolution;
uniform float time;

// TODO: should color_a and color_b accept alpha?

in float rad;
in vec2 bubble_pos;
in vec3 color_a;
in vec3 color_b;
in vec2 trans_angle;
in float trans_percent;

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
        if (color_a == color_b) {
            outcolor = vec4(color_a, a);
        } else {
            // The color of the bubble is a gradient between two colors
            // If the bubble is only meant to be a single color,
            // then the two colors should simply be the same.

            // The length of the gradient needs to stay the same no matter the percent_transitioned!
            // With a transition from color A to color B,
            // it is only the position of the gradient that changes.
            // The space on either side of the gradient should be the pure respective color
            // gradient_width is proportional to the radius of the bubble for consistency.
            // a greater gradient_width is a "smoother" transition
            float gradient_width = rad * GRADIENT_WIDTH_MULTIPLIER;
            // The gradient starts and ends just *outside* of the rendered area
            // ~~~~~~~~~~********************~~~~~~~~~~
            // ^--------^ gradient starts here

            // ~~~~~~~~~~********************~~~~~~~~~~
            //            gradient ends here ^--------^

            float dist_to_trans_origin = distance(gl_FragCoord.xy, bubble_pos + trans_angle*rad)
                // That's why we add gradient_width to dist_to_trans_origin
                + gradient_width;
            // And it adds up to the diameter plus the gradient on either side
            float transitioned_radius = (2*gradient_width + 2*rad) * trans_percent;
            // This is how we create a gradient centered around transitioned_radius
            // smoothstep will return 0 when dist_to_trans_origin is out to the "left" of the gradient
            // smoothstep will return 1 when dist_to_trans_origin is out to the "right" of the gradient
            float percent_transitioned = smoothstep(transitioned_radius - gradient_width, transitioned_radius + gradient_width, dist_to_trans_origin);
            vec3 color = mix(color_b, color_a, percent_transitioned);
            outcolor = vec4(color, a);
        }
    }
    else { discard; }
}

