

#if RAYMARCHING

const float RM_PRECISION = 0.0001;
const float RM_TMIN = 10.0 * RM_PRECISION;
const float RM_TMAX = 1000.0;
const int RM_STEP_MAX = 500;

#include "raymarching_scene.glsl"
#include "raymarching.glsl"

#define trace(ray, previousHitId, hitInfo) \
    raymarch(ray, RM_TMIN, RM_TMAX, RM_PRECISION, RM_STEP_MAX, hitInfo)

#else

#include "raytracing_scene.glsl"
#include "raytracing.glsl"

#define trace(ray, previousHitId, hitInfo) \
    raytrace(ray, previousHitId, hitInfo)

#endif

#ifdef HOOK_MATERIAL
#define getMaterial(hitInfo) HOOK_MATERIAL(hitInfo)
#else
#include "material.glsl"
Material getMaterial(HitInfo _)
{
    Material mat;
    mat.type = DIFF;
    mat.color = vec3(1.0);
    mat.emissive = vec3(0.0);
    return mat;
}
#endif
