#include "../core.glsl"
#include "../box.glsl"
#include "../sphere.glsl"
#include "materials.glsl"

#define HOOK_LIGHT_COUNT 3
#define HOOK_LIGHTS(i) uLights[i]

uniform Light uLights[] = Light[](
      Light(vec3(0.000, 1.0, 60.0), 2.0, vec3(1.0)/*vec3(1.0, 0.0, 0.0)*/, 10.0)
    , Light(vec3(-15.0, 1.0, 45.0), 2.0, vec3(1.0)/*vec3(0.0, 1.0, 0.0)*/, 10.0)
    , Light(vec3(+15.0, 1.0, 45.0), 2.0, vec3(1.0)/*vec3(0.0, 0.0, 1.0)*/, 10.0)
    , Light(vec3(40.0, 50., -50.6), 10.0, vec3(0.2, 0.65, 1.0), 30.0)
    , Light(vec3(5.0, 30., -30.6), 12.0, vec3(0.9, 0.4, 0.8), 10.0)
);

#define MATLIGHT(color) \
    MATERIAL(NO_SHADING, color, 0.0, 0.0, vec3(0.0), NO_AS)

#define SPHERE_COUNT 12
Sphere spheres[] = Sphere[](
    // Floor
    Sphere(1e5, vec3(50., -1e5, 81.6), MatGround, true),

    // Plastic balls
	Sphere(8.5, vec3(0., 8.5, 0.), MatYellow, true),
	Sphere(8.5, vec3(15., 8.5, 15.), MatRedAcrylic, true),

    // Metallic balls
    Sphere(16.5, vec3(-35., 16.5, 0.), MatSteel, true),
    Sphere(2.0, vec3(5., 2.0, 30.), MatSteel, true),
    Sphere(2.0, vec3(8., 2.0, 0.), MatSteel, true),
    Sphere(2.0, vec3(-25., 2.0, 35.), MatGold, true),
    Sphere(2.0, vec3(-15., 2.0, 60.), MatSteel, true),

    // Glass balls
    Sphere(12.0, vec3(43., 12.0, 38.), MatGlass, true)
	/*Sphere(16.5, vec3(35., 16.5, 0), Material(REFRACTIVE, lblue, black, 0.0), true),*/

	/*Sphere(5.0, vec3(15., 5.0, 35.0), Material(REFRACTIVE, lgreen, black, 0.0), true),*/
	/*Sphere(2.0, vec3(-10., 2.0, 55.), Material(REFRACTIVE, lred, black, 0.0), true)*/

    , Sphere(uLights[0].radius, uLights[0].pos, MATLIGHT(uLights[0].color), false)
    , Sphere(uLights[1].radius, uLights[1].pos, MATLIGHT(uLights[1].color), false)
    , Sphere(uLights[2].radius, uLights[2].pos, MATLIGHT(uLights[2].color), false)
);

#define BOX(center, size, mat, b) \
    Box(center - size/2.0, center+size/2.0, mat, b)

#define BOX_COUNT 0
Box boxes[] = Box[](
    BOX(vec3(0.0, 0.0, 0.0), vec3(+1e5, 0.1, +1e5), MatSteel, true),
    BOX(vec3(0.0, 80.0, 0.0), vec3(+1e5, 0.1, +1e5), MatSteel, true)
);

#undef BOX


#undef MATLIGHT

void setupCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 120.0;
    float ymin = 0.0;
    float ymax = 100.0;

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

#define HOOK_CAMERA_SETUP(camera, params) setupCamera(camera, params)

#define SUN_SKY_BACKGROUND 1

#define SUN 0

#include "../../env/sun.glsl"

Sun getSun()
{
    const Sun sun = Sun(vec2(1.58, 1.64), 3.0 * REAL_SUN_SIZE, 100.0);
    return sun;
}

#define HOOK_SUN() getSun()
