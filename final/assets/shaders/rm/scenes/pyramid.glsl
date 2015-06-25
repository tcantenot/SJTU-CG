#include "../core.glsl"
#include "../distance_fields.glsl"

#ifndef PI
#define PI 3.14159265359
#endif

#ifndef TO_RADIAN
#define TO_RADIAN(d) (d) * PI / 180.0
#endif

float torus_with_holes(vec3 p)
{
    float s = 2.0;
    float torus = sdTorus82(p-vec3(-2.0, 0.2, 2.0), s * vec2(0.20,0.1));
    vec3 reps = opRep(vec3(
        atan(p.x+2.0,p.z)/6.2831,
        p.y,
        0.02+0.5*length(p-vec3(-2.0, 0.2, 2.0))),  vec3(0.05,1.0,0.05)
    );

    float cylinders = sdCylinder(reps, vec2(0.02,0.6));

    float d = opS(torus, cylinders);
    return d;
}

float rbox_minus_sphere(vec3 p)
{
    float s = 10.0;
    float rbox = udRoundBox(p, s * vec3(0.15), s * 0.05);
    float sphere = sdSphere(p, s * 0.25);
    return opS(rbox, sphere);
}

float map(vec3 p, inout HitInfo hitInfo)
{
    const float NONE = 1e5;

    float scene = NONE;

    int id = -1;

    float cx = 0.0;
    float cz = 0.0;

    Ry(p, PI);

#define root3_over6 0.288675135
#define root3_over4 0.433012702
#define root3_over3 0.577350269
#define root6_over3 0.816496581
#define root6_over6 0.408248290
#define sqrt2 1.414213562
#define sqrt3 1.732050808

    float r = 0.6;
    float z1 = -2.0 * r * sqrt3 / 3.0;

    int pyramidId = 42;


#if 1
    float b = r;

    float sphere = 0.0;

    // First level
    sphere = sdSphere(p-vec3(-2.0*r, b, z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(0.0, b, z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(2.0*r, b, z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(-r, b, r * sqrt3 + z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(r, b, r * sqrt3 + z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(0.0, b, 2.0 * r * sqrt3 + z1), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    // Second level
    sphere = sdSphere(p-vec3(0.0, b + 2.0 * root6_over3 * r, 2.0 * root3_over3 * r), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(-r, b + 2.0 * root6_over3 * r,  z1 + root3_over3 * r), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    sphere = sdSphere(p-vec3(r, b + 2.0 * root6_over3 * r, z1 + root3_over3 * r), r);
    scene = opU(scene, sphere, id, pyramidId, id);

    // Third level
    sphere = sdSphere(p-vec3(0.0, b + 2.0 * 2.0 * root6_over3 * r, 0.0), r);
    scene = opU(scene, sphere, id, pyramidId, id);
#endif


    // Plane
    float plane = sdPlaneY(p);
    scene = opU(scene, plane, id, 0, id);

    /*cx = opRep1(p.x, 6);*/
    /*cz = opRep1(p.z, 6);*/

#if 0
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
#endif


    float m = 7.0;

    {
        float top = r + 2.0 * 2.0 * root6_over3 * r + r;
        vec3 q = p - vec3(0.0, top + sqrt2, 0.0);
        Rz(q, TO_RADIAN(45.0));
        scene = opU(scene, sdBox(q, vec3(1.0)), id, 2, id);
    }

    {
        vec3 q = p - vec3(-m, m * 0.25, -m);
        Rx(q, TO_RADIAN(90.0));
        /*Rz(q, TO_RADIAN(-60.0));*/
        scene = opU(scene, sdTorus(q, m * vec2(0.20,0.05)), id, 3, id);
    }
    scene = opU(scene, sdCapsule(p-vec3(-m, 0.6, 0.0), vec3(0.5, 0.20, -0.1), m * vec3(-0.1, 0.20, 0.1), 1.0), id, 5, id);
    scene = opU(scene, sdHexPrism(p-vec3(-m, m * 0.20, m), m * vec2(0.25, 0.05)), id, 3, id);

    scene = opU(scene, sdTorus82(p-vec3(0.0, 0.25, -m), m * vec2(0.20,0.05)), id, 4, id);
    scene = opU(scene, sdTorus88(p-vec3(0.0, 0.25, m), m * vec2(0.20,0.05)), id, 4, id);

    scene = opU(scene, sdCylinder(p-vec3(m, m * 0.15, -m), m * vec2(0.1, 0.15)), id, 3, id);
    scene = opU(scene, sdTriPrism(p-vec3(m, m * 0.05, 0.0), m * vec2(0.25, 0.05)), id, 5, id);
    scene = opU(scene, udRoundBox(p-vec3(m, (m+3) * 0.15, m), m * vec3(0.15), 0.5), id, 3, id);

    /*scene = opU(scene, udRoundBox(p-vec3( 1.0,0.25, 1.0), vec3(0.15), 0.1), id, 3, id);*/

    /*scene = opU(scene, sdCapsule(p,vec3(-1.3,0.20,-0.1), vec3(-1.0,0.20,0.2), 0.1), id, 3, id);*/
    /*scene = opU(scene, sdTriPrism(p-vec3(-1.0,0.25,-1.0), vec2(0.25,0.05)), id, 3, id);*/
    /*scene = opU(scene, sdCylinder(p-vec3( 1.0,0.30,-1.0), vec2(0.1,0.2)), id, 3, id);*/
    /*scene = opU(scene, sdCone(p-vec3( 0.0,0.50,-1.0), vec3(0.8,0.6,0.3)), id, 3, id);*/
    /*scene = opU(scene, sdTorus82(p-vec3( 0.0,0.25, 2.0), vec2(0.20,0.05)), id, 3, id);*/
    /*scene = opU(scene, sdTorus88(p-vec3(-1.0,0.25, 2.0), vec2(0.20,0.05)), id, 3, id);*/
    /*scene = opU(scene, sdCylinder6(p-vec3( 1.0,0.30, 2.0), vec2(0.1,0.2)), id, 3, id);*/
    /*scene = opU(scene, sdHexPrism(p-vec3(-1.0,0.20, 1.0), vec2(0.25,0.05)), id, 3, id);*/

    /*scene = opU(scene, torus_with_holes(p), id, 1, id);*/
    /*scene = opU(scene, rbox_minus_sphere(p), id, 4, id);*/

    /*scene = opU(scene, opS(udRoundBox(p-vec3(-2.0,0.2, 1.0), vec3(0.15),0.05),*/
                        /*sdSphere(p-vec3(-2.0,0.2, 1.0), 0.25)), id, 1, id);*/
    /*scene = opU(scene, opS(*/
                        /*sdTorus82(p-vec3(-2.0,0.2, 0.0), vec2(0.20,0.1)),*/
                        /*sdCylinder(opRep(vec3(atan(p.x+2.0,p.z)/6.2831, p.y,*/
                                              /*0.02+0.5*length(p-vec3(-2.0,0.2, 0.0))),*/
                                         /*vec3(0.05,1.0,0.05)), vec2(0.02,0.6))), id, 1, id);*/
    /*scene = opU(scene, 0.7*sdSphere(    p-vec3(-2.0,0.25,-1.0), 0.2 ) +*/
                                       /*0.03*sin(50.0*p.x)*sin(50.0*p.y)*sin(50.0*p.z),*/
                                        /*id, 1, id);*/
    /*scene = opU(scene, 0.5*sdTorus(opTwist(p-vec3(-2.0,0.25, 2.0), 10.0, 10.0),vec2(0.20, 0.05)), id, 1, id);*/

    // Lights
    scene = opU(scene, sdSphere(p-vec3(0.0, 4.0, 0.0), 0.5), id, 6, id);
    if(bool(0))
    {
        float r = 0.3;
        float d = 3.0;
        scene = opU(scene, sdSphere(p-vec3(d, r, 0.0), r), id, 6, id);
        scene = opU(scene, sdSphere(p-vec3(-d, r, 0.0), r), id, 6, id);
        scene = opU(scene, sdSphere(p-vec3(0.0, r, d), r), id, 6, id);
        scene = opU(scene, sdSphere(p-vec3(0.0, r, -d), r), id, 6, id);
    }
    if(bool(1))
    {
        float r = 0.3;
        float d = 3.0;
        /*cx = opRepInterval1(p.x, 6.0, 6.0, 12.0);*/
        /*cx = opRepSingle1(p.x, 6.0);*/
        /*cx = opRepMirror1(p.x, 6.0);*/
        cx = opRepAngle(p.xz, 6.0);
        /*cz = opRepAngle(p.xy, 30.0);*/
        /*cz = opRep1(p.z, 6.0);*/
        scene = opU(scene, sdSphere(p-vec3(0.5 * m, r, 0.0), r), id, 1, id);
        /*scene = opU(scene, sdSphere(p-vec3(-d, r, 0.0), r), id, 1, id);*/
        /*scene = opU(scene, sdSphere(p-vec3(0.0, r, d), r), id, 1, id);*/
        /*scene = opU(scene, sdSphere(p-vec3(0.0, r, -d), r), id, 1, id);*/
    }

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
    mat.as = NO_AS;

    // Checkerboard floor
    switch(id)
    {
        case 0:
        {
            mat.type = DIFFUSE;
            float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
            mat.albedo = vec3(0.02 + 0.1 * f) * 10.5;
            mat.refractiveIndex = 1.01;
            /*mat.albedo = mix(color, vec3(0.2 + 0.1 * f), 0.65);*/
            break;
        }

        case 1:
        {
            mat.type = NO_SHADING;
            vec3 c = hitInfo.cell;
            vec3 color = vec3(sin(c.z + c.x), cos(c.x * c.z), rand(c.x - c.z));
            /*if(c.x == 0 || c.y == 0) color += vec3(0.5);*/
            color = min(color, vec3(1.0));
            color *= 0.6;
            color = vec3(1.0);
            mat.albedo = color;
            mat.emissive = color;
            break;
        }

        case 2:
        {
            mat.type = REFRACTIVE;
            mat.albedo = vec3(0.8, 0.5, 0.3);
            mat.refractiveIndex = 1.01;
            mat.as = AbsorptionAndScattering(vec3(0.9, 0.3, 0.02), 4.0);
            break;
        }

        case 3:
        {
            mat.type = METALLIC;
            mat.albedo = vec3(0.3);

            /*vec3 c = hitInfo.cell;*/
            /*vec3 color = vec3(rand(c.z + c.x), rand(c.x * c.z), rand(c.x - c.z));*/
            /*mat.albedo = color;*/
            /*mat.albedo += vec3(0.1);*/

            mat.albedo = vec3(0.3);
            break;
        }

        case 4:
        {
            mat.type = DIFFUSE;
            mat.albedo = vec3(0.87, 0.15, 0.15);
            mat.refractiveIndex = 1.491;
            break;
        }

        case 5:
        {
            mat.type = DIFFUSE;
            mat.albedo = vec3(0.75, 0.75, 0.25);
            /*mat.refractiveIndex = 1.491;*/
            break;
        }

        case 6:
        {
            mat.type = NO_SHADING;
            vec3 c = hitInfo.cell;
            vec3 color = vec3(1.0);
            mat.albedo = color;
            mat.emissive = color;
            break;
        }

        case 42:
        {
            mat.type = REFRACTIVE;
            mat.albedo = vec3(1.0, 1.0, 1.0);
            mat.refractiveIndex = 1.5;
            break;
        }

        default: break;
    }

    return mat;
}

void setupCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 25.0 + (uTweaks.z * 2.0 - 1.0) * 5.0;
    float ymin = 4.0;
    float ymax = 25.0;

    vec3 pos = vec3(0.0, 0.0, z);

    float theta = mapping(vec2(0.0, 1.0), vec2(-Pi, Pi), mouse.x / resolution.x);
    float c = cos(theta);
    float s = sin(theta);

    pos.x = pos.x * c + pos.z * s;
    pos.z = pos.z * c - pos.x * s;
    pos.y = mapping(vec2(0.0, 1.0), vec2(ymin, ymax), mouse.y / resolution.y);

    camera.position = pos;
    camera.target = vec3(0.0, 5.0, 0.0);
    camera.roll = 0.0;
    camera.fov = vec2(45.0, 45.0);
    camera.aperture = 0.0;
    camera.focal = 35.0;
}

#define HOOK_MATERIAL(hitInfo) getMaterial(hitInfo)
#define HOOK_CAMERA_SETUP(camera, params) setupCamera(camera, params)

#define SUN_SKY_BACKGROUND 1

#define SUN 1

#include "../../env/sun.glsl"

Sun getSun()
{
    const Sun sun = Sun(vec2(1.58, 1.64), 3.0 * REAL_SUN_SIZE, 100.0);
    return sun;
}

/*#define HOOK_SUN() getSun()*/
