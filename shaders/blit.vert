#version 330

layout(location=0) in vec2 pos;

out vec2 uv_coord;

void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    // pos is range [-1, 1]
    // uv_coord is range [0, 1]
    uv_coord = (pos + 1) / 2;
}
