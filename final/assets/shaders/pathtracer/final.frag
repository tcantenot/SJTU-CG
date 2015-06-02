#version 140

#include "print.glsl"


in vec2 vTexCoord;

uniform bool uPrintIterationCount = true;

uniform int uIterations;
uniform vec2 uResolution;
uniform sampler2D uAccumulator;

out vec4 RenderTarget0;

vec3 tonemap(vec3 color)
{
    return pow(color, vec3(1.0 / 2.2));
}

void main()
{
    vec3 color = texture(uAccumulator, vTexCoord).rgb;
    color /= float(uIterations);
    color = tonemap(color);


    // Print the number of iterations
    if(uPrintIterationCount)
    {
        vec2 pixel = gl_FragCoord.xy;

	    // Multiples of 4x5 work best
        vec2 fontSize = vec2(8.0, 15.0);

        float value = uIterations;

        vec2 pos = vec2(-30.0, uResolution.y - 25.0);

        color = mix(color, vec3(1.0),
            printNumber(pixel, pos, fontSize, value, 8.0, 0.0)
        );
    }

    RenderTarget0 = vec4(color, 1.0);
}
