#ifndef VECTOR2_H
#define VECTOR2_H

typedef struct {
    float x, y;
} Vector2;

float vec_LengthSq(Vector2 vec);
float vec_Length(Vector2 vec);
float vec_Distance(Vector2 a, Vector2 b);
Vector2 vec_Normalized(Vector2 vec);
float vec_Dot(Vector2 a, Vector2 b);
Vector2 vec_Diff(Vector2 a, Vector2 b);
Vector2 vec_Sum(Vector2 a, Vector2 b);
Vector2 vec_Scale(Vector2 v, Vector2 f);
Vector2 vec_Mult(Vector2 v, float f);
Vector2 vec_Div(Vector2 v, float f);
Vector2 vec_Add(Vector2 v, float f);
Vector2 vec_Sub(Vector2 v, float f);

#define vec_OP_f(vec, oper, opand) (Vector2){(vec).x oper (opand), (vec).y oper (opand)}
#define vec_OP_v(vec, oper, opand) (Vector2){(vec).x oper (opand).x, (vec).y oper (opand).y}

extern Vector2 vec_zero;

#endif
