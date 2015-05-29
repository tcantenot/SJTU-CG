#include "../distance_fields.glsl"
#include "../hitinfo.glsl"
#include "../material.glsl"


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
    p -= vec3(50.0, 55.0, 30.0);
    /*p -= vec3(0.0, 30.5, 0.0);*/

    float plane = sdPlaneY(p);
    opRep1(p.x, 6);
    opRep1(p.z, 6);
    float sphere = sdSphere(p-vec3(0.0, 0.5, 0.0), 0.5);
    float box = sdBox(p-vec3(-1.2, 0.5, 0.0), vec3(0.5));
    float capsule = sdHexPrism(p-vec3(1.0, 0.5, 0.0), vec2(0.2, 0.2));

    scene = opU(scene, plane, id, 0, id);
    scene = opU(scene, box, id, 1, id);
    scene = opU(scene, sphere, id, 2, id);
    scene = opU(scene, capsule, id, 3, id);
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
    mat.color = vec3(1.0);
    mat.emissive = vec3(0.0);

    // Checkerboard floor
    if(id == 0)
    {
        mat.type = DIFFUSE;
        float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
        mat.color = vec3(0.02 + 0.1 * f) * 10.5;
        /*mat.color = mix(color, vec3(0.2 + 0.1 * f), 0.65);*/
    }
    else if(id == 1)
    {
        mat.type = SPECULAR;
        mat.color = vec3(1.0);//vec3(0.9, 0.5, 0.4);
    }
    else if(id == 2)
    {
        mat.type = REFRACTIVE;
        mat.color = vec3(1.0, 1.0, 1.0);
        /*mat.color = vec3(1.0, 0.0, 1.0);*/
    }
    else if(id == 3)
    {
        mat.type = DIFFUSE;
        mat.color = vec3(1.0, 1.0, 1.0);
        mat.emissive = vec3(0.8, 1.5, 0.3);
    }

    return mat;
}

#define HOOK_MATERIAL(hitInfo) HookMaterial(hitInfo)
