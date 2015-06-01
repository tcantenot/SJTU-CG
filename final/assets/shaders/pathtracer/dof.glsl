#include "camera.glsl"
#include "params.glsl"
#include "ray.glsl"
#include "sampling.glsl"

Ray getDOFRay(Camera camera, Params params)
{
    vec2 pixel = params.pixel;
    vec2 resolution = params.resolution;

    vec3 pos = camera.position;

    vec3 cameraUp = vec3(sin(camera.roll), cos(camera.roll), 0.0);
    vec3 forward = normalize(camera.target - camera.position);
    vec3 right = normalize(cross(forward, cameraUp));
    vec3 up = normalize(cross(right, forward));

    vec2 fov = camera.fov;
    vec3 horizontal = right * tan(fov.x * 0.5 * PI / 180.0);
    vec3 vertical   = up * tan(fov.y * 0.5 * PI / 180.0);

    /*vec2 offset = diskConcentricSample();*/
    vec2 offset = vec2(rand(), rand());

    vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;

    vec3 center = camera.position + forward;
    vec3 pointOnImagePlane = center + p.x * horizontal + p.y * vertical;

    // Point on focal plane: point at focal distance from the eye on the
    // 'eye to pixel on the screen' ray
    vec3 focalPoint = pos + (pointOnImagePlane - pos) * camera.focal;

    vec3 aperturePoint;
    const float eps = 0.00001;

    // DOF
    if(camera.aperture > eps)
    {
        // Get a sample point in the circular aperture

        float r1 = rand();
        float r2 = rand();

        float angle = 2.0 * PI * r1;
        float dist = camera.aperture * sqrt(r2);

        float apertureX = cos(angle) * dist;
        float apertureY = sin(angle) * dist;

        aperturePoint = camera.position + (apertureX * right) + (apertureY * up);
    }
    else
    {
        aperturePoint = camera.position;
    }

    Ray ray;
    ray.origin = aperturePoint;
    ray.direction = normalize(focalPoint - aperturePoint);

    return ray;
}
