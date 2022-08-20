#ifndef VECTOR2_H
#define VECTOR2_H
#define VEC2_PREF vec

typedef struct {
    float x, y;
} Vector2;

#define DECLARE_INNER(pref, name) pref ## _ ## name
#define DECLARE(pref, name) DECLARE_INNER(pref, name)
#define vec2decl(name) DECLARE(VEC2_PREF, name)

void vec2decl(Scale) (Vector2 vec, Vector2 scale);
float vec2decl(LengthSq) (Vector2 vec);
float vec2decl(Length) (Vector2 vec);
void vec2decl(Normalize) (Vector2 vec);
float vec2decl(Dot) (Vector2 a, Vector2 b);
Vector2 vec2decl(Sub) (Vector2 a, Vector2 b);
Vector2 vec2decl(Mult) (Vector2 vec, float mult);
Vector2 vec2decl(Div) (Vector2 vec, float div);

#endif
