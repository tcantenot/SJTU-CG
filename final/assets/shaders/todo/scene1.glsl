#include "hitinfo.glsl"
#include "material.glsl"
#include "operators.glsl"
#include "params.glsl"
#include "primitives.glsl"


const float NONE = 1e20;

const int NONE_ID     = -1;
const int PLANE_ID    = 0;
const int BOX_ID      = 1;
const int SPHERE_ID   = 2;
const int CYLINDER_ID = 3;

const int MATERIAL_COUNT = 4;

uniform Material uMaterials[MATERIAL_COUNT] = Material[MATERIAL_COUNT]
(
    Material(vec3(0.2), vec3(0.2, 0.8, 0.7), vec3(1.0), 64.0),
    Material(vec3(0.2), vec3(0.5, 0.9, 0.5), vec3(1.0), 100.0),
    Material(vec3(0.2), vec3(0.5, 0.5, 0.9), vec3(1.0), 128.0),
    Material(vec3(0.2), vec3(0.5, 0.3, 0.0), vec3(1.0), 16.0)
);


float Hook_Map(vec3 pos, inout HitInfo hitInfo)
{
    float scene = NONE;

    // Plane
    float plane = sdPlaneY(pos+vec3(0, 0.5, 0));

    // Box
    vec3 bpos = pos;
    float boxCell = 0.0;
    /*float boxCell = opRepMirror2(bpos.xz, vec2(1.0)).x;*/
    float box = sdBox(bpos, vec3(0.2, 0.1, 0.2));

    // Sphere
    vec3 spos = pos;
    float sphereCell = opRep1(spos.y, 1.1);
    float sphere = sdSphere(spos, 0.5);

    // Cylinder
    vec3 cpos = pos;
    float cylinderCell = opRepMirror2(cpos.xz, vec2(1.0)).x;
    float cylinder = sdCylinder(cpos+vec3(0.0, 0.2, 0.0), vec2(0.1, 0.5));

    int id = NONE_ID;
    scene = opU(scene, plane, id, PLANE_ID, id);
    scene = opU(scene, box, id, BOX_ID, id);
    scene = opU(scene, sphere, id, SPHERE_ID, id);
    scene = opU(scene, cylinder, id, CYLINDER_ID, id);
    scene = opU(scene, opCombineChamfer(box, cylinder, 0.1));

    hitInfo.id = id;

    if(id == SPHERE_ID) hitInfo.cell.x = sphereCell;
    else if(id == BOX_ID) hitInfo.cell.x = boxCell;
    else if(id == CYLINDER_ID) hitInfo.cell.x = cylinderCell;
    else hitInfo.cell.x = NONE;

    return scene;
}

Material Hook_Material(HitInfo hitInfo, Params params)
{
    Material mat;

    #if 0
    mat = uMaterials[hitInfo.id];
    #else
    mat.ambient = vec3(0.05, 0.15, 0.2);
    mat.specular = vec3(1.0, 1.0, 1.0);
    mat.shininess = 128.0;
    mat.diffuse = vec3(0.2, 0.6, 0.8);
    if(hitInfo.cell.x != NONE)
    {
        mat.diffuse.r = abs(sin(hitInfo.cell.x * 15.0));
        mat.diffuse.g = abs(cos(hitInfo.cell.x * 50.0));
        mat.diffuse.b = abs(cos(mod(hitInfo.cell.x, 0.5) * 305.2));
        mat.shininess = mix(64.0, 128.0, abs(sin(hitInfo.cell.x)));
    }
    #endif

    return mat;
}

void Hook_PostProcess(inout vec3 color, Ray ray, HitInfo hitInfo, Params params)
{
    vec3 pos = hitInfo.pos;

    // Checkerboard floor
    if(hitInfo.id == 0)
    {
        float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
        color = mix(color, vec3(0.2 + 0.1 * f), 0.65);
    }
}

#define HOOK_MAP Hook_Map
#define HOOK_MATERIAL Hook_Material
#define HOOK_POSTPROCESS Hook_PostProcess
