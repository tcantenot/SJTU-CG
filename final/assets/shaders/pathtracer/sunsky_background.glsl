#include "../fragmentarium/sunsky.glsl"
#include "ray.glsl"

vec3 skyBackground(Ray ray, int depth)
{
    return (depth > 0 ? sky(ray.direction) : sunsky(ray.direction));
}

#define HOOK_BACKGROUND skyBackground
