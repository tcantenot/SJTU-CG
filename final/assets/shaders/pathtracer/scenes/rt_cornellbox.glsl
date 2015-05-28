#include "../light.glsl"
#include "../material.glsl"

#ifdef SUN_SKY
#undef SUN_SKY
#endif

#define SUN_SKY 0

#define LIGHTS 1
#define LIGHT_COUNT 0

uniform Light uLights[] = Light[](
    Light(vec3(0.0, 600 + 99.5, 0.0), 600, vec3(1.0), 1.0)
    /*Light(vec3(155.0, 30., 30.6), 10.0, vec3(0.8, 1.5, 0.3), 13.0)*/
    ,
    Light(vec3(5.0, 30., -30.6), 12.0, vec3(0.9, 0.4, 0.8), 10.0)
    /*Light(vec3(50.0, 81.6, 81.6), 20.0, vec3(1.0), 3.0)*/

    , Light(vec3(0.000, 1.0, 60.0), 2.0, vec3(1.0, 0.0, 0.0), 10.0)
    , Light(vec3(-15.0, 1.0, 45.0), 2.0, vec3(0.0, 1.0, 0.0), 10.0)
    , Light(vec3(+15.0, 1.0, 45.0), 2.0, vec3(0.0, 0.0, 1.0), 10.0)
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


#define SPHERE_COUNT 10
Sphere spheres[] = Sphere[](
    // Red wall
    Sphere(1e5, vec3(-1e5-100.0, 0.0, 0.0), Material(DIFFUSE, red, black, 0.0), true),

    // Blue wall
    Sphere(1e5, vec3(1e5+100.0, 0.0, 0.0), Material(DIFFUSE, blue, black, 0.0), true),

    // Front wall
    Sphere(1e5, vec3(0.0, 0.0, -1e5-100.0), Material(DIFFUSE, gray, black, 0.0), true),

    // Back wall
    Sphere(1e5, vec3(0.0, 0.0, +1e5+100), Material(DIFFUSE, green, black, 0.0), true),

    // Floor
    Sphere(1e5, vec3(0.0, -1e5, 0.0), Material(DIFFUSE, gray, black, 0.0), true),
    /*Sphere(1e5, vec3(0.0, -1e5, 0.0), Material(SPECULAR, white, black, 0.0), true),*/

    // Ceiling
    Sphere(1e5, vec3(0.0, -1e5+100, 0.0), Material(DIFFUSE, gray, black, 0.0), true),

    // Plastic ball
    Sphere(8.5, vec3(0., 8.5, 0.0), Material(DIFFUSE, yellow, black, 0.0), true),

    // Metallic ball
    Sphere(16.5, vec3(-35., 16.5, 0.0), Material(SPECULAR, gray, black, 0.0), true),

    // Glass ball
    Sphere(16.5, vec3(35., 16.5, 0.0), Material(REFRACTIVE, lblue, black, 0.0), true),


    // First light
    Sphere(600.0, vec3(0.0, 600.0 + 99.5, 0.0), Material(NO_SHADING, 2.0*white, white, 0.0), true)
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(DIFFUSE, black, uLights[0].power*uLights[0].color))*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(NO_SHADING, uLights[0].color, black), false)*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(NO_SHADING, uLights[0].color, black, 0.0), false)*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(NO_SHADING, uLights[0].color, black, 0.0), false)*/

    // Second light
    /*,Sphere(uLights[1].radius, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black), false)*/
    /*,Sphere(5, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black, 0.0), false)*/

    /*,Sphere(2, uLights[2].pos, Material(NO_SHADING, uLights[2].color, black, 0.0), false)*/
    /*,Sphere(2, uLights[3].pos, Material(NO_SHADING, uLights[3].color, black, 0.0), false)*/
    /*,Sphere(2, uLights[4].pos, Material(NO_SHADING, uLights[4].color, black, 0.0), false)*/
);
