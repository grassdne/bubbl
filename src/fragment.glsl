//precision highp float;

uniform vec2 pos;
uniform float time;
uniform float outerRadius;

const float spinSpeed = 0.3;

const vec2 rad = vec2(10.0, 50.0); // [min, max]
const float numCircles = 6.0;

const vec4 colorA = vec4(0.0, 1.0, 0.0, 1.0);
const vec4 colorB = vec4(0.0, 0.0, 1.0, 1.0);

float dist;

vec4 background = vec4(1.0, 1.0, 1.0, 1.);

//Consider using distanceSquared instead of distance for efficiency
float distanceSquared(vec2 a, vec2 b) {
    float x = a.x - b.x;
    float y = a.y - b.y;
    return x*x + y*y;
}

// Why is this not built-in :|
const float PI = 3.14159265358979;

const float MAX_CIRCLES = 20.0;

vec2 aroundCircle(float percent, float radius) {
    return vec2(cos(2.0*PI * percent), sin(2.0*PI * percent)) * radius;
}

// this is what this looks like on desmos
// https://www.desmos.com/calculator/z6lbe85x2o
// awful function name
float smoothify(float x, float mod) {
    return (cos(2. * PI * x + mod) + 1.) / 2.;
}

void main() {
    gl_FragColor = background;
    
    for (float i = 0.0; i < MAX_CIRCLES; ++i) { // GLSL requires a constant max iterations
        if (i >= numCircles) break; // but we can break early
        float percentCircle = i/numCircles + time * spinSpeed;
        // absolute value cosine wave scrunched to be between [0.4, 1] multiplied by constant radius
        // factoring in time in addition to where it is along the circle 
        // means the places where blobs have high or low sizes are changing
        float r = mix(rad[0], rad[1], smoothify(percentCircle, 2.0*time));
        if ((dist = distance(gl_FragCoord.xy, pos + aroundCircle(percentCircle, outerRadius))) < r) {
            gl_FragColor *= mix(mix(colorA, colorB, smoothify(percentCircle, -2.0*time)), background, dist / r);
            // overlapping colors stack multiplicatavely
        }
    }
}

