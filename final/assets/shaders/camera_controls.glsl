#include "camera.glsl"
#include "params.glsl"

void orbitCamera(inout Camera camera, float camAngle, float camHeight, float camDistance)
{
    camera.position = vec3(
        camDistance * sin(camAngle),
        camHeight,
        camDistance * cos(camAngle)
    );
}

void moveCamera1(inout Camera camera, Params params)
{
    #if !CAMERA_MOUSE
    params.mouse = vec4(0.0);
    #endif

	camera.position = vec3(
        -0.5 + 3.2 * cos(0.1 * params.time + 6.0 * params.mouse.x),
        1.0 + 2.0 * params.mouse.y,
        0.5 + 3.2 * sin(0.1 * params.time + 6.0 * params.mouse.x)
    );
}

vec3 path(float t, float ya)
{
    vec2 p  = 100.0 * sin(0.02 * t * vec2(1.0,1.2) + vec2(0.1, 0.9));
	     p +=  50.0 * sin(0.04 * t * vec2(1.3,1.0) + vec2(1.0, 4.5));

	return vec3(p.x, 5.0 + ya * 4.0 * sin(0.05 * t), p.y);
}

void moveCamera2(inout Camera camera, Params params)
{
    camera.position = path(params.time, 1.0);
    camera.target = path(params.time+5.0, 1.0) - vec3(0.0, 6.0, 0.0);
}


void moveCamera3(inout Camera camera, Params params)
{
    float camAngle = 0.5 * params.time;
    orbitCamera(camera, camAngle, abs(0.05 + sin(params.time * 0.5)),
        smoothstep(2.0, 10.0, abs(sin(params.time)) * 5.0 + 5.0) + 2.0);
}

#define moveCamera moveCamera1
