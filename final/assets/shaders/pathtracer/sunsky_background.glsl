#include "ray.glsl"
#include "sunsky.glsl"

#ifndef SUN_SKY
#define SUN_SKY 1
#endif

vec3 skyBackground(Ray ray, int depth)
{
    #if SUN_SKY
    return (depth > 0 ? sky(ray.direction) : sunsky(ray.direction));
    #else
    return vec3(0.0);
    #endif
}

#define HOOK_BACKGROUND(ray, depth) skyBackground(ray, depth)
