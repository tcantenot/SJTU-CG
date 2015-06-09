#include "../print.glsl"

void mainImage(inout vec4 fragColor, in vec2 fragCoord)
{
    vec3 color = vec3(0.0);

    vec2 vFontSize = vec2(8.0, 15.0);
    float value = uTime;

    vec2 dim = textureSize(uTexture0, 0).xy;
    if(fragCoord.x < dim.x && fragCoord.y < dim.y)
    {
        vec2 uv = fragCoord / dim.xy;
        vec3 tex = texture(uTexture0, uv).rgb;
        color = tex;
    }
    else
    {
        color = vec3(0.0);
    }

    vec2 uv  = vec2(0.546, 1.546);

    value = texture(uTexture0, uv).g;
    color = mix(color, vec3(1.0),
        printNumber(fragCoord, vec2(1.0, uResolution.y - 15.0), vFontSize, value, 9.0, 6.0)
    );

    #if 0
    uv = fragCoord / uResolution.xy;
    uv.y = 1.0 - uv.y;
    color = texture(uTexture0, uv).rgb;
    #endif

	fragColor = vec4(color, 1.0);
}
