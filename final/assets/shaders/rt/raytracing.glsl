#include "box.glsl"
#include "core.glsl"
#include "plane.glsl"


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

vec3 getNormal(vec3 hit, Sphere sphere)
{
    return normalize(hit - sphere.pos);
}

bool raytrace(Ray ray, int avoid, const bool shadowTrace, out HitInfo hitInfo)
{
	hitInfo.id   = -1;
    hitInfo.dist = 1e5;

    Sphere hitSphere;
	for(int i = 0; i < SPHERE_COUNT; ++i)
    {
        if(i == avoid) continue;

		Sphere s = spheres[i];

        if(!s.collidable && shadowTrace) continue;

		float d = distanceTo(ray, s);
		if(d != 0.0 && d < hitInfo.dist)
        {
            hitSphere = s;
            hitInfo.dist = d;
            hitInfo.id = i;
        }
	}

    // The closest intersection has been found
    if(hitInfo.id != -1)
    {
        hitInfo.pos    = ray.origin + hitInfo.dist * ray.direction;
        hitInfo.normal = getNormal(hitInfo.pos, hitSphere);
        return true;
    }

    return false;
}

float distanceTo(Ray ray, Plane plane)
{
    const float eps = 1e-5;

    float c = dot(plane.normal, ray.direction);

    if(c > eps)
    {
        return -1.0;
    }

    return dot(plane.normal, plane.origin - ray.origin) / c;
}

vec3 getNormal(vec3 hit, Plane plane)
{
    return plane.normal;
}

bool planeIntersection(Ray ray, Plane plane, out HitInfo hitInfo)
{
	hitInfo.id   = -1;
    hitInfo.dist = 1e5;

    float d = distanceTo(ray, plane);

    if(d == -1.0) return false;

    hitInfo.dist   = d;
    hitInfo.pos    = ray.origin + hitInfo.dist * ray.direction;
    hitInfo.normal = plane.normal;

    return true;
}

// Slab method
// No intersection if tnear > tfar
vec2 distanceTo(Ray ray, Box box)
{
    const float eps = 1e-5;

    vec3 tmin = (box.min - ray.origin) / ray.direction;
    vec3 tmax = (box.max - ray.origin) / ray.direction;
    vec3 t1 = min(tmin, tmax);
    vec3 t2 = max(tmin, tmax);
    float tnear = max(max(t1.x, t1.y), t1.z);
    float tfar  = max(max(t2.x, t2.y), t2.z);

    return vec2(tnear, tfar);
}

vec3 getNormal(vec3 hit, Box box)
{
    const float eps = 1e-5;

    if(hit.x < box.min.x + eps)      return vec3(-1.0, 0.0, 0.0);
    else if(hit.x > box.min.x - eps) return vec3(+1.0, 0.0, 0.0);
    else if(hit.y < box.min.y + eps) return vec3(0.0, -1.0, 0.0);
    else if(hit.y > box.min.y - eps) return vec3(0.0, +1.0, 0.0);
    else if(hit.z < box.min.y + eps) return vec3(0.0, 0.0, -1.0);
    else return vec3(0.0, 0.0, +1.0);
}

// Slab method
bool boxIntersection(Ray ray, Box box, out HitInfo hitInfo)
{
	hitInfo.id   = -1;
    hitInfo.dist = 1e5;

    const float eps = 1e-5;

    vec2 d = distanceTo(ray, box);

    if(d.x > d.y)
    {
        return false;
    }

    hitInfo.dist   = d.x;
    hitInfo.pos    = ray.origin + hitInfo.dist * ray.direction;
    hitInfo.normal = getNormal(hitInfo.pos, box);

    return true;
}


Material HookMaterial(HitInfo hitInfo)
{
    return spheres[hitInfo.id].material;
}

#define HOOK_MATERIAL(hitInfo) HookMaterial(hitInfo)
