#include <stdio.h>
#include "../src/api.h"

int texture;
Pixel background = { 255, 0, 0, 127 };

void init(Window *window) {
    set_window_title(window, "Foo");
    texture = bg_create_texture(&background, 1, 1);
}

void on_update(double dt) {
    (void)dt;
    render_pop((Particle){
        .pos = { 200, 200 },
        .color = { 0.0, 0.0, 1.0, 1.0 },
        .radius = 50,
        .age = 0,
    });
    bg_draw(texture, &background, 1, 1);
    //printf("on_update was called!\n");
}
