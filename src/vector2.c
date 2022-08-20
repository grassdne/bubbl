#include "vector2.h"
#include <math.h>

float vec2decl( LengthSq )(Vector2 vec)
{
    return (vec.x * vec.x) + (vec.y * vec.y);
}

float vec2decl(Length) (Vector2 vec)
{
    return sqrt(vec2decl(LengthSq) (vec));
}

void vec2decl(Normalize) (Vector2 vec)
{
    float length = vec2decl(Length) (vec);
    vec.x /= length;
    vec.y /= length;
}

float vec2decl(Dot) (Vector2 a, Vector2 b)
{
    return (a.x * b.x) + (a.y * b.y);
}

Vector2 vec2decl(Sub) (Vector2 a, Vector2 b)
{
    Vector2 new;
    new.x = a.x - b.x;
    new.y = a.y - b.y;
    return new;
}

void vec2decl(Scale) (Vector2 vec, Vector2 scale)
{
    vec.x *= scale.x;
    vec.y *= scale.y;
}

Vector2 vec2decl(Mult) (Vector2 vec, float mult)
{
    Vector2 new;
    new.x = vec.x * mult;
    new.y = vec.y * mult;
    return new;
}

Vector2 vec2decl(Div) (Vector2 vec, float div)
{
    Vector2 new = {
        .x = vec.x / div,
        .y = vec.y / div,
    };
    return new;
}

