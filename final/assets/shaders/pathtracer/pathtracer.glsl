#define MULTIPLICITY 1
#define SAMPLES 4096
#define MAX_DEPTH 50

// Debug to see how many samples never reach a light source
#define DEBUG_NO_HIT 0

#define SUN_SKY 1
#define FRESNEL_SCHLICK 1
#define GLOSSY_REFRACTION 1

#define DOF 0

#define RAYMARCHING 0

#include "settings.glsl"


#include "../camera.glsl"

float mapping(vec2 from, vec2 to, float x)
{
    float a = from.x;
    float b = from.y;
    float c = to.x;
    float d = to.y;

    return (d - c) * (x - a) / (b - a) + c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    seed = uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

#if 0
    float time = uTime;
    time = 42.0;

	seed = time + uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

	vec2 uv = 2. * fragCoord.xy / uResolution.xy - 1.;

    vec2 mo = (2.0 * (uMouse.xy == vec2(0.0) ? 0.5 * uResolution.xy : uMouse.xy) / uResolution.xy - 1.0);

    float z = 95.0;
    z = 150.0;

	vec3 camPos = vec3(mo * vec2(0, 40.) + vec2(0.0, 40.8), z);

	vec3 cz = normalize(vec3(0., 40., 81.6) - camPos);
	vec3 cx = vec3(1., 0., 0.);
	vec3 cy = normalize(cross(cx, cz)); cx = cross(cz, cy);
	vec3 color = vec3(0.);

    vec2 pixel = fragCoord;
    vec2 resolution = uResolution;

    for(int k = 0; k < MULTIPLICITY; ++k)
    {
        float npaths = SAMPLES;
        float aa = float(npaths) / 2.0;
        for(int i = 0; i < npaths; ++i)
        {
            vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;

            SEED = pixel + offset;

            // Screen coords with antialiasing
            vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;

            #if DEBUG_NO_HIT
            vec3 test = radiance(Ray(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz)));
            if(dot(test, test) > 0.0) color += vec3(1.0); else color += vec3(0.5, 0.0, 0.1);
            #else
            color += radiance(Ray(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz)));
            #endif

            ++subframe;
        }
        color /= float(npaths);
    }

#else
    const float pi = 3.141592645;

	vec3 color = vec3(0.0);

    vec2 pixel = fragCoord;
    vec2 resolution = uResolution;

    float z = 99.0;
    vec3 ro = vec3(0.0, 0.0, z);

    float theta = mapping(vec2(0.0, 1.0), vec2(-pi, pi), uMouse.x / uResolution.x);
    float c = cos(theta);
    float s = sin(theta);

    ro.x = ro.x * c + ro.z * s;
    ro.z = ro.z * c - ro.x * s;
    ro.y = mapping(vec2(0.0, 1.0), vec2(0.0, 100.0), uMouse.y / uResolution.y);

    vec3 target = vec3(0.0);

    mat3 cam = lookAt(ro, target, 0.0);

    const float fov = 1.5;

#if 0
    const float shutterAperture = 0.6;
    float focusDistance = 150.;
    const float blurAmount = 1;


    vec3 uu = cam[0];
    vec3 vv = cam[1];
    vec3 ww = cam[2];

    vec3 e = ro; // Eye position in world space
    float d = abs(ro.z); // Perpendicular distance from eye to image plane
    float dd = ; // Distance from eye to pixel
    float f; // Focal length
    vec3 v; // Unit vector from eye to current pixel

    // Focal point
    vec3 P = e + dd / (d / (d + f)) * v;
#endif

    for(int k = 0; k < MULTIPLICITY; ++k)
    {
        const float npaths = SAMPLES;
        const float aa = float(npaths) / 2.0;
        for(int i = 0; i < npaths; ++i)
        {
            vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;

            SEED = pixel + offset;
            /*seed = uResolution.y * SEED.x / uResolution.x + SEED.y / uResolution.y;*/

            // Screen coords with antialiasing
            vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;

            // Create ray with depth of field
            vec3 er = normalize(vec3(p.xy, fov));
            vec3 rd = cam * er;

            #if DOF
            vec3 go = blurAmount * vec3(2.0 * rand2n() - 1.0, 0.0);
            /*vec3 gd = normalize(er * focusDistance - go);*/
            vec3 gd = normalize(er * focusDistance / uResolution.y);
            ro += go.x * uu + go.y * vv;
            rd += gd.x * uu + gd.y * vv;
            #endif

            rd = normalize(rd);


            Ray ray = Ray(ro, rd);
            #if DEBUG_NO_HIT
            vec3 test = radiance(ray);
            if(dot(test, test) > 0.0) color += vec3(1.0); else color += vec3(0.5, 0.0, 0.1);
            #else
            color += radiance(ray);
            #endif

            ++subframe;
        }
        color /= float(npaths);
    }

#endif

    fragColor = vec4(pow(clamp(color, 0.0, 1.0), vec3(1.0/2.2)), 1.0);
}
