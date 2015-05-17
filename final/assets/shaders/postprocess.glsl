#include "params.glsl"

void postProcess(inout vec3 color, Params params)
{
    #if GAMMA_CORRECTION
    color = pow(color, vec3(0.4545));
    #endif

    // Vignetting
    #if VIGNETTING
    vec2 q = params.fragCoord.xy / params.resolution.xy;
    color *= 0.05 + 1.0 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);
    #endif
}
