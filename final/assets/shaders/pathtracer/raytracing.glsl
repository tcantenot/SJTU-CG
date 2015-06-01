#include "material.glsl"
#include "hitinfo.glsl"
#include "ray.glsl"

float distanceTo(Ray ray, Sphere s)
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
	for(int i = 0; i < SPHERE_COUNT; ++i)
    {
        if(i == avoid) continue;

		Sphere s = spheres[i];

        if(!s.collidable && shadowTrace) continue;

		float d = distanceTo(ray, s);
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
