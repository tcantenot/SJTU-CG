#include "primitives.glsl"
#include "operators.glsl"
#include "hitinfo.glsl"

const float NONE = 1e20;

const int NONE_ID     = -1;
const int PLANE_ID    = 0;
const int BOX_ID      = 1;
const int SPHERE_ID   = 2;
const int CYLINDER_ID = 3;

float map(vec3 pos, inout HitInfo hitInfo)
{
    float scene = NONE;

    #if 1
    // Plane
    float plane = sdPlaneY(pos+vec3(0, 0.5, 0));

    // Box
    vec3 bpos = pos;
    float boxCell = opRepMirror2(bpos.xz, vec2(1.0)).x;
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
    scene = opU(scene, opCombineChamfer(box, cylinder, 0.04));

    hitInfo.id = id;

    if(id == SPHERE_ID) hitInfo.cell.x = sphereCell;
    else if(id == CYLINDER_ID) hitInfo.cell.x = cylinderCell;
    else hitInfo.cell.x = NONE;

    return scene;
}

void postProcessing(
    inout vec3 color,
    HitInfo hitInfo,
    float time,
    vec2 mouse,
    vec2 fragCoord,
    vec2 resolution
)
{
    vec3 pos = hitInfo.pos;

    // Checkerboard floor
    if(hitInfo.id == 0)
    {
        float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
        color = mix(color, vec3(0.2 + 0.1 * f), 0.65);
    }
}
