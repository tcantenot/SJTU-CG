// Distance field functions of various primitives
//
// From:
// - http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

#include "utils.glsl"


// PLANE

// n = (normal.xyz, distance)
float sdPlane(vec3 p, vec4 n)
{
    return dot(p, n.xyz) + n.w;
}

float sdPlaneX(vec3 p)
{
    return p.x;
}

float sdPlaneY(vec3 p)
{
    return p.y;
}

float sdPlaneZ(vec3 p)
{
    return p.z;
}


// BOX

// b = (dx, dy, dz) // distances to center of the box
float sdBox(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
    return min(max3(d), 0.0) + length(max(d, 0.0));
}

// Infinite box in one axis
float sdBox2(vec2 p, vec2 b)
{
    vec2 d = abs(p) - b;
    return min(max2(d), 0.0) + length(max(d, 0.0));
}

// b = (dx, dy, dz) // distances to center of the box
float udBox(vec3 p, vec3 b)
{
    return length(max(abs(p) - b, 0.0));
}

// b = (dx, dy, dz) // distances to center of the box
float udRoundBox(vec3 p, vec3 b, float r)
{
    return length(max(abs(p) - b, 0.0)) - r;
}


// SPHERE

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}


// CYLINDER

// c = (radius, length)
float sdCylinder(vec3 p, vec2 c)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - c;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// c = (radius, length)
float sdCylinder6(vec3 p, vec2 c)
{
    return max(length6(p.xz) - c.x, abs(p.y) - c.y);
}


// CAPSULE

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}


// CONE

float sdCone(vec3 p, vec3 c)
{
    vec2 q = vec2(length(p.xz), p.y);
    #if 0
    return max(max(dot(q, c.xy), p.y), -p.y - c.z);
    #else
    float d1 = -p.y - c.z;
    float d2 = max(dot(q, c.xy), p.y);
    return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.0);
    #endif
}


// TORUS

float sdTorus(vec3 p, vec2 t)
{
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

float sdTorus82(vec3 p, vec2 t)
{
    vec2 q = vec2(length2(p.xz) - t.x, p.y);
    return length8(q) - t.y;
}

float sdTorus88(vec3 p, vec2 t)
{
    vec2 q = vec2(length8(p.xz) - t.x, p.y);
    return length8(q) - t.y;
}


// PRISM

float sdTriPrism(vec3 p, vec2 h)
{
    vec3 q = abs(p);
    #if 0
    return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
    #else
    float d1 = q.z - h.y;
    float d2 = max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5;
    return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.0);
    #endif
}

float sdHexPrism(vec3 p, vec2 h)
{
    vec3 q = abs(p);
    #if 0
    return max(q.z - h.y,max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x);
    #else
    float d1 = q.z - h.y;
    float d2 = max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x;
    return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.0);
    #endif
}
