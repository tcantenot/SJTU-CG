#include "../core/random.glsl"

float test_rand()
{
    return randHashInt(gRandSeed++);
    return rand(gRandSeed++);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    randomSeedInit(fragCoord, uResolution, uIterations);

    float r = test_rand();

    for(int i = 0; i < 100; i++)
    {
        r = test_rand();
    }

    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

    if(r < 0.33) color.x = 1.0;
    else if(r < 0.66) color.y = 1.0;
    else color.z = 1.0;

    vec4 expected = vec4(0.33, 0.33, 0.33, 1.0);

    float x = fragCoord.x / uResolution.x;

    fragColor = mix(color, expected, float(x > 0.5));
}
