#include "../core.glsl"
#include "../distance_fields.glsl"

float map(vec3 p, inout HitInfo hitInfo)
{
    const float NONE = 1e5;

    float scene = NONE;

    int id = -1;

    float cx = 0.0;
    float cz = 0.0;

#define root3_over6 0.288675135
#define root3_over4 0.433012702
#define root3_over3 0.577350269
#define root6_over3 0.816496581
#define root6_over6 0.408248290
#define sqrt3 1.732050808

    float r = 0.2;
    float z1 = -2.0 * r * sqrt3 / 3.0;

    int pyramidId = 42;

#if 0
    float sphere = 0.0;

    // First level
    sphere = sdSphere(p-vec3(-2.0*r, 0.0, z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(0.0, 0.0, z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(2.0*r, 0.0, z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(-r, 0.0, r * sqrt3 + z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(r, 0.0, r * sqrt3 + z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(0.0, 0.0, 2.0 * r * sqrt3 + z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    // Second level
    sphere = sdSphere(p-vec3(0.0, 0.0 + 2.0 * root6_over3 * r, 2.0 * root3_over3 * r), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(-r, 0.0 + 2.0 * root6_over3 * r,  z1 + root3_over3 * r), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(r, 0.0 + 2.0 * root6_over3 * r, z1 + root3_over3 * r), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    // Third level
    sphere = sdSphere(p-vec3(0.0, 0.0 + 2.0 * 2.0 * root6_over3 * r, 0.0), r);
    scene = opU(scene, sphere, id, pyramidId, id);
#endif


    // Plane
    float plane = sdPlaneY(p+vec3(0.0, r, 0.0));
    scene = opU(scene, plane, id, 0, id);

    /*cx = opRep1(p.x, 6);*/
    /*cz = opRep1(p.z, 6);*/

    // Capsule
    float capsule = sdHexPrism(p-vec3(1.0, 0.5, 0.0), vec2(0.2, 0.2));
    scene = opU(scene, capsule, id, 1, id);

    // Box
    float box = sdBox(p-vec3(-1.2, 0.5, 0.0), vec3(0.5));
    scene = opU(scene, box, id, 2, id);

    // Round box
    float rbox = udRoundBox(p-vec3(-1.2, 0.5, 5.0), vec3(0.5), 0.2);
    scene = opU(scene, rbox, id, 3, id);

    float cone = sdCone(p-vec3(1.2, 0.5, 3.0), vec3(0.5));
    scene = opU(scene, cone, id, 4, id);

    float torus = sdTorus88(p-vec3(3.2, 0.5, 3.0), vec2(0.5));
    scene = opU(scene, torus, id, 5, id);

    float cylinder = sdCylinder(p-vec3(-1.2, 1.0, 0.0), vec2(0.1, 5.0));
    scene = opU(scene, cylinder, id, 6, id);

    hitInfo.cell.xz = vec2(cx, cz);
    hitInfo.id = id;

    return scene;
}

Material getMaterial(HitInfo hitInfo)
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
        mat.type = DIFFUSE;
        mat.albedo = vec3(0.8, 0.5, 0.3);
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
    else if(id == 42)
    {
        mat.type = REFRACTIVE;
        mat.albedo = vec3(1.0, 1.0, 1.0);
        mat.refractiveIndex = 1.5;
    }

    return mat;
}

void setupCamera(inout Camera camera, Params params)
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

#define HOOK_MATERIAL(hitInfo) getMaterial(hitInfo)
#define HOOK_CAMERA_SETUP(camera, params) setupCamera(camera, params)
