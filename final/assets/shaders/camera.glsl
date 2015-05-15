/*
    Camera class & camera utils
*/

#include "ray.glsl"

struct Camera
{
    vec3 position;
    float focal;
    vec3 target;
    float roll;
};

mat3 lookAt(vec3 origin, vec3 target, float roll)
{
    vec3 r = vec3(sin(roll), cos(roll), 0.0);
    vec3 w = normalize(target - origin);
    vec3 u = normalize(cross(w, r));
    vec3 v = cross(u, w);

    return mat3(u, v, w);
}

vec2 getScreenPos(vec2 fragCoord, vec2 screenResolution)
{
    float aspect = screenResolution.x / screenResolution.y;
    vec2 q = fragCoord / screenResolution;
    vec2 p = 2.0 * q - 1.0;
    p.x *= aspect;
    return p;
}

vec3 getRayDir(mat3 camMat, float camFocal, vec2 screenPos)
{
    return normalize(camMat * vec3(screenPos, camFocal));
}

vec3 getRayDir(vec3 origin, vec3 target, float camFocal, float roll, vec2 screenPos)
{
    mat3 camMat = lookAt(origin, target, roll);
    return getRayDir(camMat, camFocal, screenPos);
}

vec3 getRayDir(vec3 origin, vec3 target, float camFocal, vec2 screenPos)
{
    return getRayDir(origin, target, camFocal, 0.0, screenPos);
}

vec3 getRayDir(vec3 origin, vec3 target, float camFocal, float roll, vec2 fragCoord, vec2 screenResolution)
{
    return getRayDir(origin, target, camFocal, roll, getScreenPos(fragCoord, screenResolution));
}

vec3 getRayDir(vec3 origin, vec3 target, float camFocal, vec2 fragCoord, vec2 screenResolution)
{
    return getRayDir(origin, target, camFocal, 0.0, getScreenPos(fragCoord, screenResolution));
}

vec3 getRayDir(Camera cam, vec2 fragCoord, vec2 screenResolution)
{
    return getRayDir(cam.position, cam.target, cam.focal, cam.roll, fragCoord, screenResolution);
}

Ray getRay(Camera camera, vec2 fragCoord, vec2 screenResolution)
{
    Ray ray;
    ray.origin = camera.position;
    ray.direction = getRayDir(camera, fragCoord, screenResolution);
    return ray;
}

void orbitCamera(inout Camera camera, float camAngle, float camHeight, float camDistance)
{
    camera.position = vec3(
        camDistance * sin(camAngle),
        camHeight,
        camDistance * cos(camAngle)
    );
}

void moveCamera1(inout Camera camera, float time, vec2 mouse, vec2 fragCoord, vec2 resolution)
{
	camera.position = vec3(
        -0.5 + 3.2 * cos(0.1 * time + 6.0 * mouse.x),
        1.0 + 2.0 * mouse.y,
        0.5 + 3.2 * sin(0.1 * time + 6.0 * mouse.x)
    );
}

vec3 path(float t, float ya)
{
    vec2 p  = 100.0 * sin(0.02 * t * vec2(1.0,1.2) + vec2(0.1, 0.9));
	     p +=  50.0 * sin(0.04 * t * vec2(1.3,1.0) + vec2(1.0, 4.5));

	return vec3(p.x, 5.0 + ya * 4.0 * sin(0.05 * t), p.y);
}

void moveCamera2(inout Camera camera, float time, vec2 mouse, vec2 fragCoord, vec2 resolution)
{
    camera.position = path(time, 1.0);
    camera.target = path(time+5.0, 1.0) - vec3(0.0, 6.0, 0.0);
}


void moveCamera3(inout Camera camera, float time, vec2 mouse, vec2 fragCoord, vec2 resolution)
{
    float camAngle = 0.5 * time;
    orbitCamera(camera, camAngle, abs(0.05 + sin(time * 0.5)),
        smoothstep(2.0, 10.0, abs(sin(time)) * 5.0 + 5.0) + 2.0);
}

#define moveCamera moveCamera1
