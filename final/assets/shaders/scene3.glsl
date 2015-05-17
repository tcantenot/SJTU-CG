#include "hitinfo.glsl"
#include "operators.glsl"
#include "primitives.glsl"
#include "transforms.glsl"

const float NONE = 1e20;

float Hook_Map(vec3 p, inout HitInfo hitInfo)
{
    float scene = NONE;
    hitInfo.id = 1;

#if 0
    /*opRepAngle(p.xz, 4);*/
    /*opMirror2(p.xz, vec2(90, 80));*/
    /*opMirror2(p.xz, vec2(40, 60));*/

    p.x = -abs(p.x) + 10;

    opRep1(p.z, 20.0);

    float wall = sdBox2(p.xy, vec2(1, 15));

    p.z = abs(p.z) - 3.0;
    p.z = abs(p.z) + 1.5;

    float box = sdBox(p, vec3(3, 9, 4));

    p.y -= 9;
    float cylinder = sdCylinder(p.yxz, vec2(4, 3));

    p.y -= 6;
    Rz(p, -0.5);
    p.x -= 18;
    float roof = sdBox2(p.xy, vec2(20, 0.5));

    float window = opU(cylinder, box);

    wall = opDivideChamfer(wall, window, 0.2);

    float building = opU(wall, roof);

    scene = building;
#else
    opRepMirror2(p.xz, vec2(8));
    scene = sdSphere(p, 1.0);
    /*scene = opU(scene, sdBox(p, vec3(1.0)));*/
#endif

    return scene;
}

#define HOOK_MAP Hook_Map
