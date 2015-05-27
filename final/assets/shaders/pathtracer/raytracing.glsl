#include "material.glsl"
#include "hitinfo.glsl"
#include "ray.glsl"

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

// FIXME: dependency on uLights

#define NUM_SPHERES 6
Sphere spheres[NUM_SPHERES] = Sphere[](
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
	Sphere(8.5, vec3(45., 8.5, 78.), Material(DIFFUSE, yellow, black, 0.0), true),

    // Metallic ball
	Sphere(16.5, vec3(27., 16.5, 47.), Material(SPECULAR, gray, black, 0.0), true),

    // Glass ball
	Sphere(16.5, vec3(73., 16.5, 78.), Material(REFRACTIVE, lblue, black, 0.0), true)


    // First light
    /*Sphere(600., vec3(50., 681.33, 81.6), 2.0*white, black, DIFFUSE)*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(DIFFUSE, black, uLights[0].power*uLights[0].color))*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(NO_SHADING, uLights[0].color, black), false)*/
    ,Sphere(5.0, uLights[0].pos, Material(NO_SHADING, 2.0*uLights[0].color, black, 0.0), false)

    // Second light
    /*,Sphere(uLights[1].radius, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black), false)*/
    ,Sphere(5, uLights[1].pos, Material(NO_SHADING, uLights[1].color, black, 0.0), false)
);


float distance(Ray ray, Sphere s)
{
    const float EPSILON = 1e-3;
	vec3 op = s.pos - ray.origin;
    float b = dot(op, ray.direction);
    float det = b * b - dot(op, op) + s.radius * s.radius;

	float t;
	if(det < 0.0) // No intersection
    {
        return 0.0;
    }
    else
    {
        det = sqrt(det);
    }

	return (t = b - det) > EPSILON ? t : ((t = b + det) > EPSILON ? t : 0.0);
}

bool raytrace(Ray ray, int avoid, const bool shadowTrace, out HitInfo hitInfo)
{
	hitInfo.id   = -1;
    hitInfo.dist = 1e5;

    Sphere hit;
	for(int i = 0; i < NUM_SPHERES; ++i)
    {
        if(i == avoid) continue;

		Sphere s = spheres[i];

        if(!s.collidable && shadowTrace) continue;

		float d = distance(ray, s);
		if(d != 0.0 && d < hitInfo.dist)
        {
            hit = s;
            hitInfo.dist = d;
            hitInfo.id = i;
        }
	}

    // The closest intersection has been found
    if(hitInfo.id != -1)
    {
        hitInfo.pos    = ray.origin + hitInfo.dist * ray.direction;
        hitInfo.normal = normalize(hitInfo.pos - hit.pos);
        return true;
    }

    return false;
}

Material HookMaterial(HitInfo hitInfo)
{
    return spheres[hitInfo.id].material;
}

#define HOOK_MATERIAL(hitInfo) HookMaterial(hitInfo)
