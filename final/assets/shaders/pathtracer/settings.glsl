#include "camera.glsl"
#include "fresnel.glsl"
#include "hitinfo.glsl"
#include "light.glsl"
#include "material.glsl"
#include "params.glsl"
#include "random.glsl"
#include "ray.glsl"
#include "sampling.glsl"
#include "utils.glsl"


////////////////////////////////////////////////////////////////////////////////
///                        RAYMARCHING / RAYTRACING                          ///
////////////////////////////////////////////////////////////////////////////////

#if RAYMARCHING

const float RM_PRECISION = 0.0001;
const float RM_TMIN = 10.0 * RM_PRECISION;
const float RM_TMAX = 1000.0;
const int RM_STEP_MAX = 500;

#include "raymarching_scene.glsl"
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


////////////////////////////////////////////////////////////////////////////////
///                                 CAMERA                                   ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_CAMERA
#define SetupCamera(camera, params) HOOK_CAMERA(camera, params)
#else
void SetupCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 100.0;
    float ymin = 0.0;
    float ymax = 100.0;

    vec3 pos = vec3(0.0, 0.0, z);

    float theta = mapping(vec2(0.0, 1.0), vec2(-Pi, Pi), mouse.x / resolution.x);
    float c = cos(theta);
    float s = sin(theta);

    pos.x = pos.x * c + pos.z * s;
    pos.z = pos.z * c - pos.x * s;
    pos.y = mapping(vec2(0.0, 1.0), vec2(ymin, ymax), mouse.y / resolution.y);

    camera.position = pos;
    camera.target = vec3(0.0);
    camera.roll = 0.0;
    camera.fov = vec2(45.0, 45.0);
    camera.aperture = 0.0;
    camera.focal = 35.0;
}
#endif


////////////////////////////////////////////////////////////////////////////////
///                                MATERIAL                                  ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_MATERIAL
#define getMaterial(hitInfo) HOOK_MATERIAL(hitInfo)
#else
Material getMaterial(HitInfo _)
{
    const Material m = MATERIAL(DIFFUSE, vec3(1.0), 0.0, 0.0, vec3(0.0), NO_AS);
    return m;
}
#endif


////////////////////////////////////////////////////////////////////////////////
///                               BACKGROUND                                 ///
////////////////////////////////////////////////////////////////////////////////

#include "sunsky_background.glsl"

#ifdef HOOK_BACKGROUND
#define background(ray, depth) HOOK_BACKGROUND(ray, depth)
#else
vec3 background(Ray ray, int depth)
{
    return vec3(0.0);
}
#endif


////////////////////////////////////////////////////////////////////////////////
///                                RADIANCE                                  ///
////////////////////////////////////////////////////////////////////////////////
#include "radiance.glsl"


////////////////////////////////////////////////////////////////////////////////
///                              POSTPROCESS                                 ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_POSTPROCESS
#define PostProcess(color, ray, params) HOOK_POSTPROCESS(color, ray, params)
#else
void PostProcess(inout vec3 color, Ray ray, Params params) { }
#endif


