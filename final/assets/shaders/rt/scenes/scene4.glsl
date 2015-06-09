#include "../core.glsl"
#include "../sphere.glsl"
#include "materials.glsl"

#define LIGHTS 0
#define LIGHT_COUNT 1

#undef SUN_SKY
#define SUN_SKY 1

uniform Light uLights[] = Light[](
    Light(vec3(-4.0, 15.0, 0.0), 6.0, vec3(13, 13, 11), 1.0),
    Light(vec3(-4.0, 15.0, 0.0), 6.0, vec3(13, 13, 11), 1.0)
);

const Material MatWLight = MATERIAL(DIFFUSE,
    vec3(0.0), 0.0, 0.0, vec3(5.0), NO_AS
);


#define SPHERE_COUNT 16
Sphere spheres[] = Sphere[](
    Sphere(1e5, vec3(0.0, -1e5-0.8, 0.0), MatGround, true),
    Sphere(0.8, vec3(-0.9, 0.0, -0.9), MatSomething, true),
    Sphere(0.4, vec3(-0.5, -0.4, 1.0), MatMarble, true),
    Sphere(0.1, vec3(-1.0, -0.7, 1.2), MatMarble, true),
    Sphere(0.1, vec3(-0.5, -0.7, 1.7), MatMarble, true),
    Sphere(0.1, vec3(0.3, -0.7, 1.4), MatMarble, true),
    Sphere(0.1, vec3(-0.1, -0.7, 0.1), MatMarble, true),
    Sphere(0.25, vec3(0.2, -0.55, 0.7), MatMarble, true),
    Sphere(0.3, vec3(0.9, -0.5, 1.3), MatGreenGlass, true),
    Sphere(0.8, vec3(0.8, 0.0, -0.4), MatKetchup, true),
    Sphere(0.4, vec3(0.8, 1.2, -0.4), MatKetchup, true),
    Sphere(0.2, vec3(0.8, 1.8, -0.4), MatKetchup, true),
    Sphere(0.1, vec3(0.8, 2.1, -0.4), MatKetchup, true),
    Sphere(0.05, vec3(0.8, 2.25, -0.4), MatKetchup, true),
    Sphere(0.025, vec3(0.8, 2.325, -0.4), MatKetchup, true),
    Sphere(6.0, vec3(-4.0, 15.0, 0.0), MatWLight, false)
);

void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 6.0;
    float ymin = -1.0;
    float ymax = 10.0;

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
    camera.fov = vec2(25.0);
    camera.aperture = 0.0;
    camera.focal = 50.0;
}

#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
