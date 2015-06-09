#include "../core.glsl"
#include "../sphere.glsl"
#include "materials.glsl"

// FIXME: deprecated

#define LIGHTS 0
#define LIGHT_COUNT 3

uniform Light uLights[] = Light[](

    Light(vec3(40.0, 50., -50.6), 10.0, vec3(0.2, 0.65, 1.0), 30.0)
    /*Light(vec3(155.0, 30., 30.6), 10.0, vec3(0.8, 1.5, 0.3), 13.0)*/
    /*,*/
    ,Light(vec3(5.0, 30., -30.6), 12.0, vec3(0.9, 0.4, 0.8), 10.0)
    /*Light(vec3(50.0, 81.6, 81.6), 20.0, vec3(1.0), 3.0)*/

    ,
    Light(vec3(0.000, 1.0, 60.0), 2.0, vec3(1.0)/*vec3(1.0, 0.0, 0.0)*/, 10.0)
    , Light(vec3(-15.0, 1.0, 45.0), 2.0, vec3(1.0)/*vec3(0.0, 1.0, 0.0)*/, 10.0)
    , Light(vec3(+15.0, 1.0, 45.0), 2.0, vec3(1.0)/*vec3(0.0, 0.0, 1.0)*/, 10.0)
);


/*const vec3 white  = vec3(1.0);*/
/*const vec3 black  = vec3(0.0);*/
/*const vec3 gray   = vec3(0.75);*/
/*const vec3 red    = vec3(0.75, 0.25, 0.25);*/
/*const vec3 green  = vec3(0.25, 0.75, 0.25);*/
/*const vec3 blue   = vec3(0.25, 0.25, 0.75);*/
/*const vec3 yellow = vec3(0.75, 0.75, 0.25);*/
/*const vec3 lgreen = vec3(0.7, 1.0, 0.9);*/
/*const vec3 lblue  = vec3(0.7, 0.8, 0.9);*/
/*const vec3 lred   = vec3(0.7, 0.5, 0.4);*/


#define SPHERE_COUNT 9
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


    // First light
    /*Sphere(600., vec3(50., 681.33, 81.6), 2.0*white, black, DIFFUSE)*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(DIFFUSE, black, uLights[0].power*uLights[0].color))*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(NO_SHADING, uLights[0].color, black), false)*/
    /*,Sphere(5.0, uLights[0].pos, Material(NO_SHADING, 2.0*uLights[0].color, black, 0.0), false)*/

    // Second light
    /*,Sphere(uLights[1].radius, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black), false)*/
    /*,Sphere(5, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black, 0.0), false)*/

    /*,Sphere(2, uLights[2].pos, Material(NO_SHADING, uLights[2].color, black, 0.0), false)*/
    /*,Sphere(2, uLights[3].pos, Material(NO_SHADING, uLights[3].color, black, 0.0), false)*/
    /*,Sphere(2, uLights[4].pos, Material(NO_SHADING, uLights[4].color, black, 0.0), false)*/
);

void HookCamera(inout Camera camera, Params params)
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

#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
