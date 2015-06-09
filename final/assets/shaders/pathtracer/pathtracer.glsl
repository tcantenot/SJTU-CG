#define MULTIPLICITY 1
#define SAMPLES 64
#define MAX_DEPTH 50

// Debug to see how many samples never reach a light source
#define DEBUG_NO_HIT 0

#define SUN_SKY 1

#define RAYMARCHING 0

#include "camera.glsl"
#include "dof.glsl"
#include "params.glsl"
#include "settings.glsl"

uniform int uSamples;

//TODO:
// - HookCameraSetup
// - HookTonemap
// - HookMaterial
// - HookScene

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Initialize random seed
    gSeed = uResolution.y * float(uIterations) * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

    gSeed = float(uIterations) * 1000.0 + uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;
    gSeed = uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;
    gSeed *= float(uIterations);

    // Initialize params
    Params params = Params(gl_FragCoord.xy, uResolution, uMouse, uTime);

    // Initialize camera
    Camera camera;

    SetupCamera(camera, params);

    /*camera.aperture = uTweaks.x;*/
    /*camera.focal = uTweaks.y * 100.0;*/

    vec3 color = vec3(0.0);
    int samples = 0;
    for(int k = 0; k < MULTIPLICITY; ++k)
    {
        for(int i = 0; i < uSamples; ++i)
        {
            // Get jittered ray with depth of field
            Ray ray = getDOFRay(camera, params);

            #if DEBUG_NO_HIT
            vec3 test = radiance(ray);
            if(dot(test, test) > 0.0) color += vec3(1.0); else color += vec3(0.5, 0.0, 0.1);
            #else
            vec3 c = radiance(ray);
            PostProcess(c, ray, params);
            color += c;
            #endif

            ++samples;
        }
    }

    color /= float(samples);

    fragColor = vec4(color, 1.0);
}
