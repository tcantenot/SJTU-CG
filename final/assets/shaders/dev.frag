#version 140

#define LIGHTING 1
#define LIGHTING_OCCLUSION 1
#define LIGHTING_SHADOWS 1

#define GAMMA_CORRECTION 1
#define VIGNETTING 1

#define ISOLINES_DEBUG 0
#define CAMERA_MOUSE 1

#include "camera.glsl"
#include "camera_controls.glsl"
#include "hitinfo.glsl"
#include "isolines.glsl"
#include "light.glsl"
#include "lighting.glsl"
#include "material.glsl"
#include "params.glsl"
#include "scene.glsl"


in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse;

out vec4 RenderTarget0;


#define QUALITY 4

#if QUALITY == 0
const int AA_SAMPLES = 16;
const float PRECISION = 0.00001;
const float TMIN = 0.1;
const float TMAX = 5000.0;
const int STEP_MAX = 4096;
#elif QUALITY == 1
const int AA_SAMPLES = 8;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
const float TMAX = 500.0;
const int STEP_MAX = 1000;
#elif QUALITY == 2
const int AA_SAMPLES = 4;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
const float TMAX = 200.0;
const int STEP_MAX = 500;
#elif QUALITY == 3
const int AA_SAMPLES = 2;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
const float TMAX = 100.0;
const int STEP_MAX = 250;
#else
const int AA_SAMPLES = 1;
const float PRECISION = 0.001;
const float TMIN = 0.1;
const float TMAX = 100.0;
const int STEP_MAX = 100;
#endif


// Lights
const int LIGHT_COUNT = 2;
uniform Light uLights[LIGHT_COUNT] = Light[LIGHT_COUNT]
(
    Light(vec4(normalize(vec3(-0.6, 0.7, -0.5)), 0.0), vec3(0.9, 0.6, 0.3), 0.7),
    Light(vec4(normalize(vec3(-0.6, 0.7, 0.5)), 0.0), vec3(0.9, 0.7, 0.5), 0.9)
);


// Compute normal by central differences on the distance field at the shading point
// (gradient approximation)
vec3 calcNormal(vec3 pos)
{
    vec3 eps = vec3(0.001, 0.0, 0.0);
    vec3 normal = vec3(
        map(pos+eps.xyy) - map(pos-eps.xyy),
        map(pos+eps.yxy) - map(pos-eps.yxy),
        map(pos+eps.yyx) - map(pos-eps.yyx)
    );
    return normalize(normal);
}

float castRay(
    Ray ray,
    const float tmin, const float tmax,
    const float precis, const int stepmax,
    inout HitInfo hitInfo
)
{
    vec3 ro = ray.origin;
    vec3 rd = ray.direction;
    float t = tmin;

    // Raymarching using sphere tracing
    for(int i = 0; i < stepmax; i++)
    {
        float d = map(ro + t * rd, hitInfo);
        t += d;
        if(d < precis || t > tmax) break;
    }

    if(t > tmax)  // No hit
    {
        hitInfo.id = -1;
    }
    else
    {
        // Store hit info
        hitInfo.dist   = t;
        hitInfo.pos    = ro + t * rd;
        hitInfo.normal = calcNormal(hitInfo.pos);
    }

    return t;
}

vec3 raytrace(Ray ray, Params params)
{
    vec3 color = vec3(0.0);

    // Cast ray and get intersection info
    HitInfo hitInfo;
    float t = castRay(ray, TMIN, TMAX, PRECISION, STEP_MAX, hitInfo);

    if(hitInfo.id >= 0) // Object hit
    {
        vec3 pos = hitInfo.pos;
        vec3 normal = hitInfo.normal;
        vec3 view = -normalize(ray.direction);

        // Get the material of the hit object
        Material mat = getMaterial(hitInfo, params);

        #if LIGHTING
        // Apply Phong lighting model
        const float lightCount = LIGHT_COUNT;
        for(int i = 0; i < lightCount; ++i)
        {
            Light light = uLights[i];
            color += phong(pos, normal, view, light, mat);
        }
        #else
        color = mat.diffuse;
        #endif

        // Post-processing effects
        postProcess(color, hitInfo, params);

        #if ISOLINES_DEBUG
        {
            float y = 2.0 * params.mouse.y - 1.0;
            vec3 isolines = vec3(0.0);
            if(isolinesDebug(ray, t, y, isolines))
            {
                color = mix(color, isolines, 0.90);
            }
        }
        #endif
    }
    else // Background
    {
        vec2 uv = vTexCoord;
        color = vec3(uv, 0.5 + 0.5 * sin(1.0));
        /*color = vec3(uv, 0.5 + 0.5 * sin(uTime));*/
    }

    return clamp(color, 0.0, 1.0);
}


void main()
{
    // Input parameters
    Params params = Params(gl_FragCoord.xy, uResolution, uMouse/uResolution.xyxy, uTime);
    params.time = 42.0;

    // Camera
    Camera camera = Camera(vec3(1.0), 1.25, vec3(0.0), 0.0);
    moveCamera(camera, params);


    /// Ray tracing (sphere tracing) ///

    vec3 color = vec3(0.0);

    // Multisample antialiasing
    float aa = float(AA_SAMPLES) / 2.0;
    for(int i = 0; i < AA_SAMPLES; i++)
    {
        vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;
        Ray ray = getRay(camera, params.fragCoord + offset, params.resolution);
        color += raytrace(ray, params); // Cast ray through the scene
    }
    color /= float(AA_SAMPLES);


    #if GAMMA_CORRECTION
    color = pow(color, vec3(0.4545));
    #endif

    // Vignetting
    #if VIGNETTING
    vec2 q = params.fragCoord.xy / params.resolution.xy;
    color *= 0.05 + 1.0 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);
    #endif

    RenderTarget0 = vec4(color, 1.0);
}
