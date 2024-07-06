#version 330

layout(location = 0) out vec4 outcolor;

in vec4 color_a;
in vec3 local_coord;

void main() {
    float f = distance(local_coord, vec3(0.0f, 0.0f, 1.0f));
    outcolor = mix(vec4(1.0, 1.0, 1.0, 1.0), color_a, f);
}
