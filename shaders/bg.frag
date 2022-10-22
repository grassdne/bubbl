#version 330
#define MAX_ELEMENTS 10

layout(location = 0) out vec4 outcolor;

uniform vec2 positions[MAX_ELEMENTS];
uniform vec3 colors[MAX_ELEMENTS];
uniform int num_elements;
const float TRANSPARENCY = 0.33;
in float LENGTH;

void main() {
    float count = 0;
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
        ++count;

    }
    if (count == 0) discard;

    color /= count;
    outcolor = vec4(colors[closest] * (1 - closest_dist / (LENGTH/4)) + color, TRANSPARENCY);
}
