#version 140

#include "debug/print.glsl"
#include "sfx/tonemap.glsl"

in vec2 vTexCoord;

uniform bool uPrintStats = true;
uniform bool uDarkFont   = false;

uniform vec2 uResolution;
uniform int uIterations;
uniform float uFramerate;
uniform float uRenderTime;
uniform sampler2D uAccumulator;

out vec4 RenderTarget0;

void main()
{
    // Average and tonemap the colors of the accumulator
    vec3 color = texture(uAccumulator, vTexCoord).rgb;
    color /= float(uIterations);
    color = Uncharted2Tonemap(color);

    // Print the number of iterations
    if(uPrintStats)
    {
        vec2 pixel = gl_FragCoord.xy;

        // Multiples of 4x5 work best
        vec2 fontSize = vec2(8.0, 10.0);

        vec3 fontColor = mix(vec3(1.0), vec3(0.0), float(uDarkFont));

        float xleft  = -40.0;
        float xright = uResolution.x - 80.0;

        // FPS
        {
            float value = 1000.0 / uFramerate;

            vec2 pos = vec2(xleft, uResolution.y - 2.0 * fontSize.y);

            color = mix(color, fontColor,
                printNumber(pixel, pos, fontSize, value, 8.0, 2.0)
            );
        }

        // Framerate
        {
            float value = uFramerate;

            vec2 pos = vec2(xleft, uResolution.y - 2.0 * fontSize.y - 15.0);

            color = mix(color, fontColor,
                printNumber(pixel, pos, fontSize, value, 8.0, 2.0)
            );
        }

        // Average framerate
        {
            float value = float(uIterations) / uRenderTime;

            vec2 pos = vec2(xleft, uResolution.y - 2.0 * fontSize.y - 30.0);

            color = mix(color, fontColor,
                printNumber(pixel, pos, fontSize, value, 8.0, 2.0)
            );
        }

        // Frame number
        {
            float value = uIterations;

            vec2 pos = vec2(xright, uResolution.y - 2.0 * fontSize.y);

            color = mix(color, fontColor,
                printNumber(pixel, pos, fontSize, value, 8.0, 0.0)
            );
        }

        // Render time
        {
            float value = uRenderTime;

            vec2 pos = vec2(xright - 3.0 * fontSize.x, uResolution.y - 2.0 * fontSize.y - 15.0);

            color = mix(color, fontColor,
                printNumber(pixel, pos, fontSize, value, 8.0, 2.0)
            );
        }
    }

    RenderTarget0 = vec4(color, 1.0);
}
