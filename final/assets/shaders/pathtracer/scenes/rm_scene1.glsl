#include "../camera.glsl"
#include "../distance_fields.glsl"
#include "../hitinfo.glsl"
#include "../material.glsl"
#include "../random.glsl"
#include "../utils.glsl"


float map(vec3 p, inout HitInfo hitInfo)
{
    const float NONE = 1e5;

    float scene = NONE;

    int id = -1;

#if 0
    p -= vec3(50.0, 20.0, 30.0);

    float sphere = NONE;

    sphere = sdSphere(p-vec3(90.0, 0.0, 0.0), 30.0);
    scene = opU(scene, sphere, id, 3, id);

    opRep1(p.x, 150.0);
    /*opRep1(p.z, 200.0);*/

    /*sphere = sdBox(p, vec3(40.0));*/
    sphere = sdSphere(p, 40.0);
    /*float box = sdBox(p+vec3(1.2, 0.0, 0.0), vec3(0.5));*/
    scene = opU(scene, sphere, id, 2, id);
#else
    /*p -= vec3(50.0, 0.0, 30.0);*/
    /*p -= vec3(0.0, 30.5, 0.0);*/

    float plane = sdPlaneY(p);

    float cx = opRep1(p.x, 6);
    float cz = opRep1(p.z, 6);

    float sphere = sdSphere(p-vec3(0.0, 0.5, 0.0), 0.5);
    float box = sdBox(p-vec3(-1.2, 0.5, 0.0), vec3(0.5));
    float capsule = sdHexPrism(p-vec3(1.0, 0.5, 0.0), vec2(0.2, 0.2));

    scene = opU(scene, plane, id, 0, id);
    scene = opU(scene, box, id, 1, id);
    scene = opU(scene, sphere, id, 2, id);
    scene = opU(scene, capsule, id, 3, id);

    hitInfo.cell.xz = vec2(cx, cz);
#endif

    hitInfo.id = id;

    return scene;
}

Material HookMaterial(HitInfo hitInfo)
{
    int id = hitInfo.id;
    vec3 pos = hitInfo.pos;

    Material mat;
    mat.type = DIFFUSE;
    mat.albedo = vec3(1.0);
    mat.emissive = vec3(0.0);
    mat.refractiveIndex = 0.0;
    mat.roughness = 0.0;

    // Checkerboard floor
    if(id == 0)
    {
        mat.type = DIFFUSE;
        float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
        mat.albedo = vec3(0.02 + 0.1 * f) * 10.5;
        /*mat.albedo = mix(color, vec3(0.2 + 0.1 * f), 0.65);*/

    }
    else if(id == 1)
    {
        mat.type = METALLIC;
        mat.albedo = vec3(0.3);

        /*vec3 c = hitInfo.cell;*/
        /*vec3 color = vec3(rand(c.z + c.x), rand(c.x * c.z), rand(c.x - c.z));*/
        /*mat.albedo = color;*/
        /*mat.albedo += vec3(0.1);*/

        mat.albedo = vec3(0.3);
    }
    else if(id == 2)
    {
        mat.type = REFRACTIVE;
        mat.albedo = vec3(1.0, 1.0, 1.0);
        mat.refractiveIndex = 1.5;
    }
    else if(id == 3)
    {
        mat.type = NO_SHADING;
        vec3 c = hitInfo.cell;
        vec3 color = vec3(rand(c.z + c.x), rand(c.x * c.z), rand(c.x - c.z));
        if(c.x == 0 || c.y == 0) color += vec3(0.5);
        mat.albedo = color;
        mat.emissive = color;
    }

    return mat;
}

void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 5.0;
    float ymin = 0.0;
    float ymax = 10.0;

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
    camera.aperture = 0.0;
    camera.focal = 35.0;
}

#define HOOK_MATERIAL(hitInfo) HookMaterial(hitInfo)
#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
