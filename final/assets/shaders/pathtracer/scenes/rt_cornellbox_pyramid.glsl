#include "../light.glsl"
#include "materials.glsl"
#include "rt_sphere.glsl"

#ifdef SUN_SKY
#undef SUN_SKY
#endif

#define SUN_SKY 1

#define LIGHTS 0
#define LIGHT_COUNT 1

uniform Light uLights[] = Light[](

    /*Light(vec3(-4.0, 25.0, 0.0), 10, vec3(1.0), 1.0)*/
    Light(vec3(0.0, 600.0 + 80.999, 0.0), 600, vec3(1.0), 1.0)
    , Light(vec3(0.000, 1.0, 30.0), 2.0, vec3(1.0, 0.0, 0.0), 20.0)
    , Light(vec3(-15.0, 1.0, 45.0), 2.0, vec3(0.0, 1.0, 0.0), 20.0)
    , Light(vec3(+15.0, 1.0, 45.0), 2.0, vec3(0.0, 0.0, 1.0), 20.0)
);
const Material MatCGlass = Material(REFRACTIVE,
    vec3(0.75, 0.25, 0.25), 1.33, 0.0, vec3(0.0),
    /*NO_AS*/
    AbsorptionAndScattering(vec3(0.01, 0.8, 0.9), 0.4)
);
const Material MatCRed = Material(REFRACTIVE,
    vec3(0.75, 0.25, 0.25), 1.33, 0.0, vec3(0.0),
    //NO_AS
    AbsorptionAndScattering(vec3(0.5, 0.8, 0.9), 1.0)
);

const Material MatCGreen = Material(DIFFUSE,
    vec3(0.25, 0.75, 0.25), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCBlue = Material(DIFFUSE,
    vec3(0.25, 0.25, 0.75), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCYellow = Material(DIFFUSE,
    vec3(0.75, 0.75, 0.25), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCBlack = Material(DIFFUSE,
    vec3(0.0), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCWhite = Material(NO_SHADING,
    vec3(1.0), 0.0, 0.0, vec3(1.0), NO_AS
);

const Material MatCAlmostBlack = Material(DIFFUSE,
    vec3(0.01), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCGray = Material(DIFFUSE,
    vec3(0.75), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCMirror = Material(METALLIC,
    vec3(1.0), 0.0, 0.0, vec3(0.0), NO_AS
);

const Material MatCGlossyMirror = Material(METALLIC,
    vec3(1.0), 0.0, 0.1, vec3(0.0), NO_AS
);

const Material MatCLBlueGlass = Material(REFRACTIVE,
    vec3(0.7, 0.8, 0.9), 1.5, 0.0, vec3(0.0), NO_AS
);

const Material MatCLightNoShading = Material(NO_SHADING,
    vec3(5.0), 0.0, 0.0, vec3(0.0), NO_AS
);

#define MATLIGHT(color) \
    Material(NO_SHADING, color, 0.0, 0.0, vec3(0.0), NO_AS)

#define root3_over6 0.288675135
#define root3_over4 0.433012702
#define root3_over3 0.577350269
#define root6_over3 0.816496581
#define root6_over6 0.408248290
#define sqrt3 1.732050808

float r = 0.5;
float z1 = -2.0 * r * sqrt3 / 3.0;

#define SPHERE_COUNT 11
Sphere spheres[] = Sphere[](

    // Red wall
    /*Sphere(1e5, vec3(-1e5-80.0, 0.0, 0.0), MatCRed, true),*/
    Sphere(2.5, vec3(0.0, 0.5, 0.0), MatCGlass, true),

    // Blue wall
    /*Sphere(1e5, vec3(1e5+80.0, 0.0, 0.0), MatCBlue, true),*/
    /*Sphere(1e5, vec3(1e5+5.0, 0.0, 0.0), MatCMirror, true),*/

    // Front wall
    /*Sphere(1e5, vec3(0.0, 0.0, -1e5-85.0), MatCGray, true),*/

    // Back wall
    /*Sphere(1e5, vec3(0.0, 0.0, +1e5+150.0), MatCBlack, true),*/

    // Floor
    /*Sphere(1e5, vec3(0.0, -1e5, 0.0), MatCGray, true),*/
    /*Sphere(1e5, vec3(0.0, -1e5, 0.0), MatCGlossyMirror, true),*/
    /*Sphere(1e5, vec3(0.0, -1e5, 0.0), MatCAlmostBlack, true),*/

    // Ceiling
    /*Sphere(1e5, vec3(0.0, -1e5+81.6, 0.0), MatCGray, true),*/

    // Pyramid

    // First level
    Sphere(r, vec3(-2.0*r, 0.0, z1), MatCBlue, true),
    Sphere(r, vec3(0.0, 0.0, z1), MatCWhite, true),
    Sphere(r, vec3(2.0*r, 0.0, z1), MatCBlue, true),
    Sphere(r, vec3(-r, 0.0, r * sqrt3 + z1), MatCWhite, true),
    Sphere(r, vec3(r, 0.0, r * sqrt3 + z1), MatCWhite, true),
    Sphere(r, vec3(0.0, 0.0, 2.0 * r * sqrt3 + z1), MatCBlue, true),

    // Second level
    Sphere(r, vec3(0.0, 0.0 + 2.0 * root6_over3 * r, 2.0 * root3_over3 * r), MatCYellow, true),
    Sphere(r, vec3(-r, 0.0 + 2.0 * root6_over3 * r,  z1 + root3_over3 * r), MatCYellow, true),
    Sphere(r, vec3(r, 0.0 + 2.0 * root6_over3 * r, z1 + root3_over3 * r), MatCYellow, true),

    // Third level
    Sphere(r, vec3(0.0, 0.0 + 2.0 * 2.0 * root6_over3 * r, 0.0), MatCWhite, true),


    // Ceiling light
    Sphere(600.0, vec3(0.0, 600.0 + 81.0, 0.0), MatCLightNoShading, false)

    , Sphere(uLights[1].radius, uLights[1].pos, MATLIGHT(uLights[1].color), false)
    , Sphere(uLights[2].radius, uLights[2].pos, MATLIGHT(uLights[2].color), false)
    , Sphere(uLights[3].radius, uLights[3].pos, MATLIGHT(uLights[3].color), false)
);


void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 10.0;
    float ymin = 0.0;
    float ymax = 3.0;

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
    camera.fov = vec2(45.0);
    camera.aperture = 0.0;
    camera.focal = 35.0;
}

#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
