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
