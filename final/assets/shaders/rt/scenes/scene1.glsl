#include "../core.glsl"
#include "../sphere.glsl"
#include "materials.glsl"

#define LIGHTS 1
#define LIGHT_COUNT 5

uniform Light uLights[] = Light[](

    Light(vec3(40.0, 50., -50.6), 10.0, vec3(0.2, 0.65, 1.0), 30.0)
    /*Light(vec3(155.0, 30., 30.6), 10.0, vec3(0.8, 1.5, 0.3), 13.0)*/
    ,
    Light(vec3(5.0, 30., -30.6), 12.0, vec3(0.9, 0.4, 0.8), 10.0)
    /*Light(vec3(50.0, 81.6, 81.6), 20.0, vec3(1.0), 3.0)*/

    , Light(vec3(0.000, 1.0, 60.0), 2.0, vec3(1.0)/*vec3(1.0, 0.0, 0.0)*/, 10.0)
    , Light(vec3(-15.0, 1.0, 45.0), 2.0, vec3(1.0)/*vec3(0.0, 1.0, 0.0)*/, 10.0)
    , Light(vec3(+15.0, 1.0, 45.0), 2.0, vec3(1.0)/*vec3(0.0, 0.0, 1.0)*/, 10.0)
);


struct Sphere
{
	float radius;
	vec3 pos;
    Material material;
    bool collidable;
};

const vec3 white  = vec3(1.0);
const vec3 black  = vec3(0.0);
const vec3 gray   = vec3(0.75);
const vec3 red    = vec3(0.75, 0.25, 0.25);
const vec3 green  = vec3(0.25, 0.75, 0.25);
const vec3 blue   = vec3(0.25, 0.25, 0.75);
const vec3 yellow = vec3(0.75, 0.75, 0.25);
const vec3 lgreen = vec3(0.7, 1.0, 0.9);
const vec3 lblue  = vec3(0.7, 0.8, 0.9);


#define SPHERE_COUNT 9
Sphere spheres[] = Sphere[](
    // Red wall
    /*Sphere(1e5, vec3(-1e5+1., 40.8, 81.6), Material(DIFFUSE, red, black, 0.0)),*/

    // Blue wall
    /*Sphere(1e5, vec3( 1e5+99., 40.8, 81.6), Material(DIFFUSE, blue, black, 0.0)),*/

    // Front wall
    /*Sphere(1e5, vec3(50., 40.8, -1e5), Material(DIFFUSE, gray, black, 0.0)),*/

    // Back wall
    /*Sphere(1e5, vec3(50., 40.8,  1e5+170), Material(DIFFUSE, green, black, 0.0)),*/

    // Floor
    Sphere(1e5, vec3(50., -1e5, 81.6), Material(DIFFUSE, white, black, 0.1), true),
    /*Sphere(1e5, vec3(50., -1e5, 81.6), Material(SPECULAR, white, black, 0.1), true),*/

    // Ceiling
    /*Sphere(1e5, vec3(50.,  1e5+81.6, 81.6), Material(DIFFUSE, gray, black, 0.0)),*/

    // Plastic ball
	/*Sphere(8.5, vec3(45., 8.5, 78.), Material(DIFFUSE, yellow, black, 0.0), true),*/
	Sphere(8.5, vec3(0., 8.5, 0.), Material(DIFFUSE, yellow, black, 0.0), true),

    // Metallic ball
	/*Sphere(16.5, vec3(27., 16.5, 47.), Material(SPECULAR, gray, black, 0.0), true),*/
	Sphere(16.5, vec3(-35., 16.5, 0.), Material(SPECULAR, gray, black, 0.0), true),

    // Glass ball
	/*Sphere(16.5, vec3(73., 16.5, 78.), Material(REFRACTIVE, lblue, black, 0.0), true)*/
	Sphere(16.5, vec3(35., 16.5, 0), Material(REFRACTIVE, lblue, black, 0.0), true)


    // First light
    /*Sphere(600., vec3(50., 681.33, 81.6), 2.0*white, black, DIFFUSE)*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(DIFFUSE, black, uLights[0].power*uLights[0].color))*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(NO_SHADING, uLights[0].color, black), false)*/
    ,Sphere(5.0, uLights[0].pos, Material(NO_SHADING, 2.0*uLights[0].color, black, 0.0), false)

    // Second light
    /*,Sphere(uLights[1].radius, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black), false)*/
    ,Sphere(5, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black, 0.0), false)

    ,Sphere(2, uLights[2].pos, Material(NO_SHADING, uLights[2].color, black, 0.0), false)
    ,Sphere(2, uLights[3].pos, Material(NO_SHADING, uLights[3].color, black, 0.0), false)
    ,Sphere(2, uLights[4].pos, Material(NO_SHADING, uLights[4].color, black, 0.0), false)
);

void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 100.0;
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
    camera.aperture = 0.5;
    camera.focal = 35.0;
}

#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
