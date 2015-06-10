#define MULTIPLICITY 1
#define MAX_DEPTH 50

// Debug to see how many samples never reach a light source
#define DEBUG_NO_HIT 0

#define SUN_SKY 1

#define RAYMARCHING 0

#include "core.glsl"

#if DEBUG_NO_HIT
#include "../debug/debug_no_hit.glsl"
#endif

#include "settings.glsl"

uniform int uSamples;

//TODO:
// - HookTonemap
// - HookScene

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Initialize random seed
    randomSeedInit(fragCoord, uResolution, uIterations);

    // Initialize params
    Params params = Params(gl_FragCoord.xy, uResolution, uMouse, uTime);

    // Initialize camera
    Camera camera;

    HookCameraSetup(camera, params);

    /*camera.aperture = uTweaks.x;*/
    /*camera.focal = uTweaks.y * 100.0;*/

    vec3 color = vec3(0.0);
    int samples = 0;
    for(int k = 0; k < MULTIPLICITY; ++k)
    {
        for(int i = 0; i < uSamples; ++i)
        {
            // Get jittered ray with depth of field
            Ray ray = HookDOFRay(camera, params);

            vec3 c = radiance(ray);

            HookPostProcess(c, ray, params);

            color += c;

            ++samples;
        }
    }

    color /= float(samples);

    fragColor = vec4(color, 1.0);
}
