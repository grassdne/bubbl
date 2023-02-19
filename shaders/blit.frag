#version 330

uniform sampler2D pixels;

layout(location = 0) out vec4 outcolor;

in vec2 uv_coord;

void main() {
    outcolor = texture(pixels, uv_coord);
}
