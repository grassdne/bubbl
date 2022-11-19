#version 330
#define MAX_ELEMENTS 10

layout(location = 0) out vec4 outcolor;

uniform vec2 positions[MAX_ELEMENTS];
uniform vec3 colors[MAX_ELEMENTS];
uniform int num_elements;
uniform vec2 resolution;
const float TRANSPARENCY = 0.33;
in float LENGTH;     // Length of resolution (distance botoom left -> top right)
const float EFFECTIVENESS_FACTOR = 0.22;

void main() {
    int closest = 0;
    float closest_dist = LENGTH;

    vec3 color = vec3(0);

    for (int i = 0; i < MAX_ELEMENTS; ++i) {
        if (i >= num_elements) break;

        float dist = distance(gl_FragCoord.xy, positions[i]);
        if (dist < closest_dist) {
            closest = i;
            closest_dist = dist;
        }

        color += colors[i] * (1 - dist / LENGTH);

    }

    color /= num_elements;
    outcolor = vec4(mix(colors[closest], color, smoothstep(0.0, LENGTH * EFFECTIVENESS_FACTOR, closest_dist)), TRANSPARENCY);
}
