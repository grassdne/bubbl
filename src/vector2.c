#include "vector2.h"
#include <math.h>

float vec_LengthSq(Vector2 vec)
{
    return (vec.x * vec.x) + (vec.y * vec.y);
}

float vec_Length(Vector2 vec)
{
    return sqrt(vec_LengthSq(vec));
}

float vec_Distance(Vector2 a, Vector2 b)
{
    return vec_Length(vec_Diff(a, b));
}

Vector2 vec_Normalized(Vector2 vec)
{
    return vec_Div(vec, vec_Length(vec));
}

float vec_Dot(Vector2 a, Vector2 b)
{
    return (a.x * b.x) + (a.y * b.y);
}

Vector2 vec_Diff(Vector2 a, Vector2 b)   { return vec_OP_v(a, -, b); }
Vector2 vec_Sum(Vector2 a, Vector2 b)    { return vec_OP_v(a, +, b); }
Vector2 vec_Scale(Vector2 v, Vector2 f)  { return vec_OP_v(v, *, f); }
Vector2 vec_Mult(Vector2 v, float f)     { return vec_OP_f(v, *, f); }
Vector2 vec_Div(Vector2 v, float f)      { return vec_OP_f(v, /, f); }
Vector2 vec_Add(Vector2 v, float f)      { return vec_OP_f(v, +, f); }
Vector2 vec_Sub(Vector2 v, float f)      { return vec_OP_f(v, -, f); }
