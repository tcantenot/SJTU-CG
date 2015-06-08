#include "../sphere.glsl"
#include "materials.glsl"

#define LIGHTS 0

#define SPHERE_COUNT 15
Sphere spheres[] = Sphere[](
    Sphere(1e5, vec3(0.0, -1e5-0.81, 0.0), MatGround, true),
    Sphere(0.8, vec3(-0.9, 0.0, -0.9), MatRoughSteel, true),
    Sphere(0.6, vec3(0.9, -0.2, 1.8), MatGlass, true),
    Sphere(0.4, vec3(-0.5, -0.4, 1.0), MatYellow, true),
    Sphere(0.1, vec3(-1.0, -0.7, 1.2), MatPurpleAcrylic, true),
    Sphere(0.1, vec3(-0.5, -0.7, 1.7), MatPurpleAcrylic, true),
    Sphere(0.1, vec3(0.3, -0.7, 1.4), MatPurpleAcrylic, true),
    Sphere(0.1, vec3(-0.1, -0.7, 0.1), MatPurpleAcrylic, true),
    Sphere(0.25, vec3(0.2, -0.55, 0.7), MatPurpleAcrylic, true),
    Sphere(0.8, vec3(0.8, 0.0, -0.4), MatRedAcrylic, true),
    Sphere(0.4, vec3(0.8, 1.2, -0.4), MatRedAcrylic, true),
    Sphere(0.2, vec3(0.8, 1.8, -0.4), MatRedAcrylic, true),
    Sphere(0.1, vec3(0.8, 2.1, -0.4), MatRedAcrylic, true),
    Sphere(0.05, vec3(0.8, 2.25, -0.4), MatRedAcrylic, true),
    Sphere(0.025, vec3(0.8, 2.325, -0.4), MatRedAcrylic, true),
    Sphere(5.0, vec3(0.0, 15.0, 0.0), MatWhiteLight, true)
);

void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 6.0;
    float ymin = -1.0;
    float ymax = 6.0;

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
    camera.fov = vec2(45.0, 45.0);
    camera.aperture = 0.0;
    camera.focal = 50.0;
}

#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
