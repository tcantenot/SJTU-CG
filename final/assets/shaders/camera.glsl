/*
    Camera class & camera utils
*/

#include "ray.glsl"

struct Camera
{
    vec3 position;
    float fov;
    vec3 target;
    float roll;
    vec3 up;
    float focal;
    float aperture;
    vec2 fov;
};

mat3 lookAt(vec3 origin, vec3 target, float roll)
{
    vec3 r = vec3(sin(roll), cos(roll), 0.0);
    vec3 w = normalize(target - origin);
    vec3 u = normalize(cross(w, r));
    vec3 v = cross(u, w);

    return mat3(u, v, w);
}

vec2 getScreenPos(vec2 pixel, vec2 resolution)
{
    return (2.0 * pixel - resolution) / resolution.y;
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

vec3 getRayDir(vec3 origin, vec3 target, float camFocal, float roll, vec2 pixel, vec2 resolution)
{
    return getRayDir(origin, target, camFocal, roll, getScreenPos(pixel, resolution));
}

vec3 getRayDir(vec3 origin, vec3 target, float camFocal, vec2 pixel, vec2 resolution)
{
    return getRayDir(origin, target, camFocal, 0.0, getScreenPos(pixel, resolution));
}

vec3 getRayDir(Camera cam, vec2 pixel, vec2 resolution)
{
    return getRayDir(cam.position, cam.target, cam.fov, cam.roll, pixel, resolution);
}

Ray getRay(Camera camera, vec2 pixel, vec2 resolution)
{
    Ray ray;
    ray.origin = camera.position;
    ray.direction = getRayDir(camera, pixel, resolution);
    return ray;
}
