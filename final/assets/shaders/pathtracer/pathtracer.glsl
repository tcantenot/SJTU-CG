#define MULTIPLICITY 1
#define SAMPLES 512
#define MAX_DEPTH 8

// Debug to see how many samples never reach a light source
#define DEBUG_NO_HIT 0

// Use Schlick's approximation for Fresnel effect
#define FRESNEL_SCHLICK 1

// Enable glossy refraction
#define GLOSSY_REFRACTION 1

#define SUN_SKY 1
#define RAYMARCHING 0

#include "settings.glsl"


void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    float time = uTime;
    time = 42.0;

	seed = time + uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

	vec2 uv = 2. * fragCoord.xy / uResolution.xy - 1.;

    vec2 mo = (2.0 * (uMouse.xy == vec2(0.0) ? 0.5 * uResolution.xy : uMouse.xy) / uResolution.xy - 1.0);
	vec3 camPos = vec3(mo * vec2(48., 40.) + vec2(50., 40.8), 169.);

    /*camPos.y = terrain2(camPos.xz) - 0.5;*/

	vec3 cz = normalize(vec3(50., 40., 81.6) - camPos);
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

	fragColor = vec4(pow(clamp(color, 0., 1.), vec3(1./2.2)), 1.);
    /*fragColor = vec4(uLights[0].color, 1.0);*/
}
