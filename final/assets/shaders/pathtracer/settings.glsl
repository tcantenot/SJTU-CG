#include "fresnel.glsl"
#include "hitinfo.glsl"
#include "light.glsl"
#include "material.glsl"
#include "random.glsl"
#include "ray.glsl"
#include "sampling.glsl"
#include "sunsky_background.glsl"


#if RAYMARCHING

const float RM_PRECISION = 0.0001;
const float RM_TMIN = 10.0 * RM_PRECISION;
const float RM_TMAX = 1000.0;
const int RM_STEP_MAX = 500;

#include "raymarching_scene.glsl"
/*#include "scenes/canyon.glsl"*/
#include "raymarching.glsl"

#define trace(ray, previousHitId, hitInfo) \
    raymarch(ray, RM_TMIN, RM_TMAX, RM_PRECISION, RM_STEP_MAX, hitInfo)

#define shadowtrace(ray, previousHitId, hitInfo) \
    raymarch(ray, RM_TMIN, RM_TMAX, RM_PRECISION, RM_STEP_MAX, hitInfo)

#else

#include "raytracing_scene.glsl"
#include "raytracing.glsl"

#define trace(ray, previousHitId, hitInfo) \
    raytrace(ray, previousHitId, false, hitInfo)

#define shadowtrace(ray, previousHitId, hitInfo) \
    raytrace(ray, previousHitId, true, hitInfo)

#endif


#ifdef HOOK_MATERIAL
#define getMaterial(hitInfo) HOOK_MATERIAL(hitInfo)
#else
Material getMaterial(HitInfo _)
{
    Material mat;
    mat.type = DIFFUSE;
    mat.color = vec3(1.0);
    mat.emissive = vec3(0.0);
    return mat;
}
#endif


#ifdef HOOK_BACKGROUND
#define background(ray, depth) HOOK_BACKGROUND(ray, depth)
#else
vec3 background(Ray ray, int depth)
{
    return vec3(0.0);
}
#endif

#if 0
#include "radiance1.glsl"
#else
#include "radiance2.glsl"
#endif
