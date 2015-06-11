#include "settings.glsl"

// Number of samples to take
uniform int uSamples = 1;


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Initialize random seed
    randomSeedInit(fragCoord, uResolution, uIterations);

    // Initialize params
    Params params = Params(gl_FragCoord.xy, uResolution, uMouse, uTime);

    // Initialize camera
    Camera camera;
    HookCameraSetup(camera, params);

    vec3 color = vec3(0.0);
    int samples = 0;

    // Take one or several samples
    for(int i = 0; i < uSamples; ++i)
    {
        // Get jittered ray with depth of field
        Ray ray = HookDOFRay(camera, params);

        // Compute radiance
        vec3 c = radiance(ray);

        // Post process color
        HookPostProcess(c, ray, params);

        // Accumulate
        color += c;

        ++samples;
    }

    // Average
    color /= float(samples);

    fragColor = vec4(color, 1.0);
}
