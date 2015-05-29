#define MULTIPLICITY 1
#define SAMPLES 5
#define MAX_DEPTH 50

// Debug to see how many samples never reach a light source
#define DEBUG_NO_HIT 0

#define SUN_SKY 1
#define FRESNEL_SCHLICK 1
#define GLOSSY_REFRACTION 1

#define DOF 0

#define RAYMARCHING 0

#include "settings.glsl"

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Initialize random seed
    seed = uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

    // Initialize params
    Params params = Params(gl_FragCoord.xy, uResolution, uMouse, uTime);

    // Initialize camera
    Camera camera;
    SetupCamera(camera, params);

    mat3 cam = lookAt(camera.position, camera.target, camera.roll);

    float fov = camera.fov;

    vec2 pixel = params.pixel;
    vec2 resolution = params.resolution;

#if 0
    const float shutterAperture = 0.6;
    float focusDistance = 150.;
    const float blurAmount = 1;


    vec3 uu = cam[0];
    vec3 vv = cam[1];
    vec3 ww = cam[2];

    vec3 e = ro; // Eye position in world space
    float d = abs(ro.z); // Perpendicular distance from eye to image plane
    float dd = ; // Distance from eye to pixel
    float f; // Focal length
    vec3 v; // Unit vector from eye to current pixel

    // Focal point
    vec3 P = e + dd / (d / (d + f)) * v;
#endif

    vec3 color = vec3(0.0);
    for(int k = 0; k < MULTIPLICITY; ++k)
    {
        const float npaths = SAMPLES;
        const float aa = float(npaths) / 2.0;
        for(int i = 0; i < npaths; ++i)
        {
            #define RANDOM_METHOD 1
            #if RANDOM_METHOD == 0
            vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;
            #elif RANDOM_METHOD == 1
            vec2 offset = vec2(rand(), rand());
            /*vec2 offset = diskConcentricSample();*/
            #elif RANDOM_METHOD == 2
            vec2 offset;
            if(bool(1))
            {
                vec2 p = pixel / resolution * 2.0 - 1.0;
                float phi = 2.0 * PI * rand();
                float cosa = rand();
                float sina = sqrt(1.0 - cosa * cosa);
                vec3 d = vec3(p.xy, 0.0);
                vec3 w = normalize(d);
                vec3 u = normalize(cross(w.yzx, w));
                vec3 v = cross(w, u);
                d = (u * cos(phi) + v * sin(phi)) * sina + w * cosa;
                offset = d.xy;
            }
            #elif RANDOM_METHOD == 3
            vec2 offset = hammersley2d(uint(k * SAMPLES + i), uint(MULTIPLICITY * SAMPLES));
            #endif

            SEED = pixel + offset;

            /*seed = uResolution.y * SEED.x / uResolution.x + SEED.y / uResolution.y;*/
            /*seed = rand();*/

            // Screen coords with antialiasing
            vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;

            // Create ray with depth of field

            vec3 ro = camera.position;

            vec3 er = normalize(vec3(p.xy, fov));
            vec3 rd = cam * er;

            #if DOF
            vec3 go = blurAmount * vec3(2.0 * rand2() - 1.0, 0.0);
            /*vec3 gd = normalize(er * focusDistance - go);*/
            vec3 gd = normalize(er * focusDistance / uResolution.y);
            ro += go.x * uu + go.y * vv;
            rd += gd.x * uu + gd.y * vv;
            #endif

            rd = normalize(rd);

            Ray ray = Ray(ro, rd);
            #if DEBUG_NO_HIT
            vec3 test = radiance(ray);
            if(dot(test, test) > 0.0) color += vec3(1.0); else color += vec3(0.5, 0.0, 0.1);
            #else
            color += radiance(ray);
            #endif

            ++subframe;
        }
        color /= float(npaths);
    }

    fragColor = vec4(pow(clamp(color, 0.0, 1.0), vec3(1.0/2.2)), 1.0);
}
