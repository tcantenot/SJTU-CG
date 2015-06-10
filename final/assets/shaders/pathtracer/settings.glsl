#include "core.glsl"

////////////////////////////////////////////////////////////////////////////////
///                        RAYMARCHING / RAYTRACING                          ///
////////////////////////////////////////////////////////////////////////////////

#if RAYMARCHING

const float RM_PRECISION = 0.0001;
const float RM_TMIN = 10.0 * RM_PRECISION;
const float RM_TMAX = 1000.0;
const int RM_STEP_MAX = 500;

#include "../rm/raymarching_scene.glsl"
#include "../rm/raymarching.glsl"

#define HookLightRay(ray, previousHitId, hitInfo) \
    raymarch(ray, RM_TMIN, RM_TMAX, RM_PRECISION, RM_STEP_MAX, hitInfo)

#define HookShadowRay(ray, previousHitId, hitInfo) \
    raymarch(ray, RM_TMIN, RM_TMAX, RM_PRECISION, RM_STEP_MAX, hitInfo)

#else

#include "../rt/raytracing_scene.glsl"
#include "../rt/raytracing.glsl"

#define HookLightRay(ray, previousHitId, hitInfo) \
    raytrace(ray, previousHitId, false, hitInfo)

#define HookShadowRay(ray, previousHitId, hitInfo) \
    raytrace(ray, previousHitId, true, hitInfo)

#endif


////////////////////////////////////////////////////////////////////////////////
///                                 CAMERA                                   ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_CAMERA_SETUP
#define HookCameraSetup(camera, params) HOOK_CAMERA_SETUP(camera, params)
#else
void HookCameraSetup(inout Camera camera, Params params)
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
///                                  DOF                                     ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_DOF_RAY
#define HookDOFRay(camera, params) HOOK_DOF_RAY(camera, params)
#else
#include "dof.glsl"
#endif


////////////////////////////////////////////////////////////////////////////////
///                                MATERIAL                                  ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_MATERIAL
#define HookMaterial(hitInfo) HOOK_MATERIAL(hitInfo)
#else
Material HookMaterial(HitInfo _)
{
    const Material m = MATERIAL(DIFFUSE, vec3(1.0), 0.0, 0.0, vec3(0.0), NO_AS);
    return m;
}
#endif


////////////////////////////////////////////////////////////////////////////////
///                               BACKGROUND                                 ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_BACKGROUND
#define HookBackground(ray, depth) HOOK_BACKGROUND(ray, depth)
#else
vec3 HookBackground(Ray ray, int depth)
{
    return vec3(0.0);
}
#endif

////////////////////////////////////////////////////////////////////////////////
///                                  SUN                                     ///
////////////////////////////////////////////////////////////////////////////////
#ifdef HOOK_SUN
#define HookSun() HOOK_SUN()
#else
#endif

////////////////////////////////////////////////////////////////////////////////
///                                 LIGHTS                                   ///
////////////////////////////////////////////////////////////////////////////////
#ifdef HOOK_LIGHTS
#define HookLights(index) HOOK_LIGHTS(index)
#else
Light HookLight(int index) { return Light(vec3(0.0), 0.0, vec3(0.0), 0.0); }
#endif

#ifdef HOOK_LIGHT_COUNT
#define HookLightCount HOOK_LIGHT_COUNT
#else
#define HookLightCount 0
#endif


////////////////////////////////////////////////////////////////////////////////
///                                RADIANCE                                  ///
////////////////////////////////////////////////////////////////////////////////
#include "radiance.glsl"


////////////////////////////////////////////////////////////////////////////////
///                              POSTPROCESS                                 ///
////////////////////////////////////////////////////////////////////////////////

#ifdef HOOK_POSTPROCESS
#define HookPostProcess(color, ray, params) HOOK_POSTPROCESS(color, ray, params)
#else
void HookPostProcess(inout vec3 color, Ray ray, Params params) { }
#endif
