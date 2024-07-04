#version 330

layout(location = 0) in vec2 vertex_pos;

uniform vec2 resolution;
uniform float time;
uniform mat4 transform;

layout(location = 1) in vec4 in_color_a;
layout(location = 2) in vec4 mat_0;
layout(location = 3) in vec4 mat_1;
layout(location = 4) in vec4 mat_2;
layout(location = 5) in vec4 mat_3;

out vec4 color_a;
out vec2 local_coord;

void main() {
    mat4 transf;
    transf[0] = mat_0;
    transf[1] = mat_1;
    transf[2] = mat_2;
    transf[3] = mat_3;
    gl_Position = transf * vec4(vertex_pos, 0.0f, 1.0f);

    color_a = in_color_a;
    local_coord = vertex_pos.xy;
}

/*
void main5() {
    // radius in [0, 2] scale
    vec2 radius_normalized = in_radius / resolution * 2;
    // bubble position [-1, 1] scale
    vec2 bubblepos_normalized = in_bubble / resolution * 2.0 - 1;

    vec3 local = vec3(vertex_pos, 0.0f);
    //vec3 scale = local * (resolution / in_radius);
    vec3 scale = vec3(radius_normalized, 1.0);
    vec3 offset = vec3(bubblepos_normalized, 0.0f);
    //offset = offset * 2.0f - vec3(1.0f);
    vec3 world = local * scale + offset;

    vec4 position = transform * vec4(world, 1.0);
    gl_Position = position;

    color_a = in_color_a;
    local_coord = local.xy;
}
*/


void main_7() {
    // model = mat4x4((1.000000, 0.000000, 0.000000, 0.000000), (0.000000, 0.573576, -0.819152, 0.000000), (0.000000, 0.819152, 0.573576, 0.000000), (0.000000, 0.000000, 0.000000, 1.000000))
    mat4 model;
    model[0] = vec4(1f, 0f, 0f, 0f);
    model[1] = vec4(0.000000, 0.573576, -0.819152, 0.000000);
    model[2] = vec4(0.000000, 0.819152, 0.573576, 0.000000);
    model[3] = vec4(0f, 0f, 0f, 1f);

    mat4 view;
    view[0] = vec4(1f, 0f, 0f, 0f);
    view[1] = vec4(0f, 1f, 0f, 0f);
    view[2] = vec4(0f, 0f, 1f, 0f);
    view[3] = vec4(0f, 0f,-3f, 1f);

    mat4 projection;
    projection[0] = vec4(1.810660, 0.000000, 0.000000, 0.000000);
    projection[1] = vec4(0.000000, 2.414213, 0.000000, 0.000000);
    projection[2] = vec4(0.000000, 0.000000, -1.002002, -1.000000);
    projection[3] = vec4(0.000000, 0.000000, -0.200200, 0.000000);

    gl_Position = transform * view * model * vec4(vertex_pos, 0.0, 1.0);
}


