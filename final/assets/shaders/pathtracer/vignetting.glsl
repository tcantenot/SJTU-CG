#include "params.glsl"

void vignetting(inout vec3 color, Params params)
{
    vec2 q = params.pixel.xy / params.resolution.xy;
    color *= 0.05 + 1.0 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);
}
