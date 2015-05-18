#include "hitinfo.glsl"
#include "material.glsl"
#include "params.glsl"


// Scene description
#include "scene3.glsl"


// Distance field hook
float map(vec3 pos, inout HitInfo hitInfo)
{
    #ifdef HOOK_MAP
    return HOOK_MAP(pos, hitInfo);
    #else
    hitInfo.id = -1;
    return 1e20;
    #endif
}

float map(vec3 pos)
{
    HitInfo _;
    return map(pos, _);
}

// Material selection hook
Material getMaterial(HitInfo hitInfo, Params params)
{
    #ifdef HOOK_MATERIAL
    return HOOK_MATERIAL(hitInfo, params);
    #else
    Material mat;
    mat.ambient   = vec3(0.2);
    mat.diffuse   = vec3(params.pixel/params.resolution, abs(sin(params.time)));
    mat.diffuse   = vec3(1.0);
    mat.specular  = vec3(1.0);
    mat.shininess = 64.0;
    return mat;
    #endif
}

// Post-processing hook
void postProcess(inout vec3 color, HitInfo hitInfo, Params params)
{
    #ifdef HOOK_POSTPROCESS
    HOOK_POSTPROCESS(color, hitInfo, params);
    #endif
}
