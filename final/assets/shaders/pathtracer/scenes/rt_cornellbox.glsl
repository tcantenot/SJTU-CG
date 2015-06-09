#include "../light.glsl"
#include "../sphere.glsl"
#include "materials.glsl"

#ifdef SUN_SKY
#undef SUN_SKY
#endif

#define SUN_SKY 0

#define LIGHTS 1
#define LIGHT_COUNT 1

uniform Light uLights[] = Light[](

    Light(vec3(-4.0, 25.0, 0.0), 10, vec3(1.0), 1.0)
    /*Light(vec3(0.0, 681.6 - 0.27, 0.0), 600, vec3(2.0), 1.0)*/
    , Light(vec3(0.000, 1.0, 30.0), 2.0, vec3(1.0, 0.0, 0.0), 20.0)
    , Light(vec3(-15.0, 1.0, 45.0), 2.0, vec3(0.0, 1.0, 0.0), 20.0)
    , Light(vec3(+15.0, 1.0, 45.0), 2.0, vec3(0.0, 0.0, 1.0), 20.0)
);

const Material MatCRed = MATERIAL(DIFFUSE,
    vec3(0.75, 0.25, 0.25), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCGreen = MATERIAL(DIFFUSE,
    vec3(0.25, 0.75, 0.25), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCBlue = MATERIAL(DIFFUSE,
    vec3(0.25, 0.25, 0.75), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCYellow = MATERIAL(DIFFUSE,
    vec3(0.75, 0.75, 0.25), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCBlack = MATERIAL(DIFFUSE,
    vec3(0.0), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCAlmostBlack = MATERIAL(DIFFUSE,
    vec3(0.01), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCGray = MATERIAL(DIFFUSE,
    vec3(0.75), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCMirror = MATERIAL(METALLIC,
    vec3(1.0), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCGlossyMirror = MATERIAL(METALLIC,
    vec3(1.0), 0.0, 0.02, vec3(0.0), NO_AS
);

const Material MatCLBlueGlass = MATERIAL(REFRACTIVE,
    vec3(0.7, 0.8, 0.9), 1.5, 0.0, vec3(0.0), NO_AS
);

const Material MatCLightNoShading = MATERIAL(NO_SHADING,
    vec3(5.0), 0.0, 0.0, vec3(0.0), NO_AS
);

#define MATLIGHT(color) \
    MATERIAL(NO_SHADING, color, 0.0, 0.0, vec3(0.0), NO_AS)


#define SPHERE_COUNT 9
Sphere spheres[] = Sphere[](

    // Red wall
    Sphere(1e5, vec3(-1e5-80.0, 0.0, 0.0), MatCRed, true),

    // Blue wall
    Sphere(1e5, vec3(1e5+80.0, 0.0, 0.0), MatCBlue, true),

    // Front wall
    Sphere(1e5, vec3(0.0, 0.0, -1e5-85.0), MatCGray, true),

    // Back wall
    Sphere(1e5, vec3(0.0, 0.0, +1e5+150.0), MatCBlack, true),

    // Floor
    Sphere(1e5, vec3(0.0, -1e5, 0.0), MatCGray, true),
    /*Sphere(1e5, vec3(0.0, -1e5, 0.0), MatCGlossyMirror, true),*/
    /*Sphere(1e5, vec3(0.0, -1e5, 0.0), MatCAlmostBlack, true),*/

    // Ceiling
    Sphere(1e5, vec3(0.0, -1e5+81.6, 0.0), MatCGray, true),

    // Plastic ball
    Sphere(8.5, vec3(0., 8.5, 0.0), MatCYellow, true),

    // Metallic ball
    Sphere(16.5, vec3(-35., 16.5, -35), MatCMirror, true),

    // Glass ball
    Sphere(16.5, vec3(24., 16.5, 25), MatCLBlueGlass, true),

    // Ceiling light
    /*Sphere(600.0, vec3(0.0, 600.0 + 81.0, 0.0), MatCLightNoShading, false)*/

    Sphere(20.0, vec3(0.0, 40.0, 0.0), MATLIGHT(uLights[0].color), false)
    /*Sphere(600.0, vec3(0.0, 681.6-0.27, 0.0), MATLIGHT(uLights[0].color), false)*/

    , Sphere(uLights[1].radius, uLights[1].pos, MATLIGHT(uLights[1].color), false)
    , Sphere(uLights[2].radius, uLights[2].pos, MATLIGHT(uLights[2].color), false)
    , Sphere(uLights[3].radius, uLights[3].pos, MATLIGHT(uLights[3].color), false)
);


void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 100.0;
    float ymin = 0.0;
    float ymax = 80.0;

    vec3 pos = vec3(0.0, 0.0, z);

    float theta = mapping(vec2(0.0, 1.0), vec2(-Pi, Pi), mouse.x / resolution.x);
    float c = cos(theta);
    float s = sin(theta);

    pos.x = pos.x * c + pos.z * s;
    pos.z = pos.z * c - pos.x * s;
    pos.y = mapping(vec2(0.0, 1.0), vec2(ymin, ymax), mouse.y / resolution.y);

    camera.position = pos;
    camera.target = vec3(0.0);
    camera.roll = 0.0;
    camera.fov = vec2(60.0);
    camera.aperture = 0.0;
    camera.focal = 35.0;
}

#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
