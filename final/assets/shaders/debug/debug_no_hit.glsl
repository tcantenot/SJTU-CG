#include "core.glsl"

void debugNoLightHit(inout vec3 color, Ray ray, Params params)
{
    color = mix(vec3(0.5, 0.0, 0.1), vec3(1.0), float(dot(color, color) > 0));
}

#define HOOK_POSTPROCESS(color, ray, params) debugNoLightHit(color, ray, params)
