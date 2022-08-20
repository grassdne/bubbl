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
    return vec_Length(vec_Sub(a, b));
}

void vec_Normalize(Vector2 *vec)
{
    float length = vec_Length(*vec);
    vec->x /= length;
    vec->y /= length;
}

Vector2 vec_Normalized(Vector2 vec)
{
    return vec_Div(vec, vec_Length(vec));
}

float vec_Dot(Vector2 a, Vector2 b)
{
    return (a.x * b.x) + (a.y * b.y);
}

Vector2 vec_Sub(Vector2 a, Vector2 b)
{
    return (Vector2) {a.x - b.x, a.y - b.y};
}

void vec_Scale(Vector2 *vec, Vector2 scale)
{
    vec->x *= scale.x;
    vec->y *= scale.y;
}

Vector2 vec_Mult(Vector2 vec, float mult)
{
    return (Vector2){ vec.x * mult, vec.y * mult };
}

Vector2 vec_Div(Vector2 vec, float div)
{
    return (Vector2){ vec.x / div, vec.y / div };
}

