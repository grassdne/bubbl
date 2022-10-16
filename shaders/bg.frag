#version 330
#define MAX_ELEMENTS 10

layout(location = 0) out vec4 outcolor;

uniform vec2 resolution;
uniform vec2 positions[MAX_ELEMENTS];
uniform vec3 colors[MAX_ELEMENTS];
uniform int num_elements;

const float radius = 500;

void main() {
    float max_dist = length(resolution);
    float count = 0;

    int closest = 0;
    float closest_dist = max_dist;

    vec3 color = vec3(0);

    for (int i = 0; i < MAX_ELEMENTS; ++i) {
        if (i >= num_elements) break;

        float dist = distance(gl_FragCoord.xy, positions[i]);
        if (dist < closest_dist) {
            closest = i;
            closest_dist = dist;
        }
        if (true || dist < radius) {
            color += colors[i] * (1 - dist / max_dist);
            ++count;
        }

    }
    if (count == 0) discard;

    color /= count;
    outcolor = vec4(colors[closest] * (1 - closest_dist / (max_dist/4)) + color, 0.4);
}
