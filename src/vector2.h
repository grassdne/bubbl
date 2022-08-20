#ifndef VECTOR2_H
#define VECTOR2_H

typedef struct {
    float x, y;
} Vector2;

void vec_Scale(Vector2 vec, Vector2 scale);
float vec_LengthSq(Vector2 vec);
float vec_Length(Vector2 vec);
void vec_Normalize(Vector2 vec);
float vec_Dot(Vector2 a, Vector2 b);
Vector2 vec_Sub(Vector2 a, Vector2 b);
Vector2 vec_Mult(Vector2 vec, float mult);
Vector2 vec_Div(Vector2 vec, float div);

#endif
