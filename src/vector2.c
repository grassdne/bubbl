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

void vec_Normalize(Vector2 vec)
{
    float length = vec_Length(vec);
    vec.x /= length;
    vec.y /= length;
}

float vec_Dot(Vector2 a, Vector2 b)
{
    return (a.x * b.x) + (a.y * b.y);
}

Vector2 vec_Sub(Vector2 a, Vector2 b)
{
    Vector2 new;
    new.x = a.x - b.x;
    new.y = a.y - b.y;
    return new;
}

void vec_Scale(Vector2 vec, Vector2 scale)
{
    vec.x *= scale.x;
    vec.y *= scale.y;
}

Vector2 vec_Mult(Vector2 vec, float mult)
{
    Vector2 new;
    new.x = vec.x * mult;
    new.y = vec.y * mult;
    return new;
}

Vector2 vec_Div(Vector2 vec, float div)
{
    Vector2 new = {
        .x = vec.x / div,
        .y = vec.y / div,
    };
    return new;
}

