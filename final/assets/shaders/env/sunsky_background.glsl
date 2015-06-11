#include "sunsky.glsl"

#ifndef SUN_SKY_BACKGROUND
#define SUN_SKY_BACKGROUND 1
#endif

vec3 skyBackground(vec3 dir, int depth)
{
    #if SUN_SKY_BACKGROUND
        #if SUN
        return (depth > 0 ? sky(dir) : sunsky(dir));
        #else
        return sky(dir);
        #endif
    #else
    return vec3(0.0);
    #endif
}
