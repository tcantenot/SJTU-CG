#version 140

#include "camera.glsl"
#include "primitives.glsl"
#include "operators.glsl"

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse = vec4(0.0);

out vec4 RenderTarget0;

#define LIGHTING 1
#define OCCLUSION 1
#define SHADOWS 1

#define GAMMA_CORRECTION 1
#define VIGNETTING 1

#define ISOLINES_DEBUG 1
#define MOUSE 0

#define QUALITY 3

#if QUALITY == 0
const int AA_SAMPLES = 16;
const float PRECISION = 0.00001;
const float TMIN = 0.1;
const float TMAX = 5000.0;
const int STEP_MAX = 4096;
#elif QUALITY == 1
const int AA_SAMPLES = 8;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
const float TMAX = 500.0;
const int STEP_MAX = 1000;
#elif QUALITY == 2
const int AA_SAMPLES = 4;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
const float TMAX = 200.0;
const int STEP_MAX = 500;
#elif QUALITY == 3
const int AA_SAMPLES = 2;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
const float TMAX = 100.0;
const int STEP_MAX = 250;
#else
const int AA_SAMPLES = 1;
const float PRECISION = 0.001;
const float TMIN = 0.1;
const float TMAX = 500.0;
const int STEP_MAX = 100;
#endif

const float NONE = 1e20;

struct Light
{
    vec4 position;
    vec3 color;
    float power;
};

struct Material
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct HitInfo
{
    int id;
    vec3 pos;
    float dist;
    vec3 normal;
    vec3 cell;
    //vec3 uvw;
};

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

const int LIGHT_COUNT = 2;

uniform Light uLights[LIGHT_COUNT] = Light[LIGHT_COUNT]
(
    Light(vec4(normalize(vec3(-0.6, 0.7, -0.5)), 0.0), vec3(0.9, 0.6, 0.3), 0.7),
    Light(vec4(normalize(vec3(-0.6, 0.7, 0.5)), 0.0), vec3(0.9, 0.7, 0.5), 0.9)
);


float map(vec3 pos, inout HitInfo hitInfo)
{
    float scene = NONE;

    // Plane
    float plane = sdPlaneY(pos+vec3(0, 0.5, 0));

    // Box
    float box = sdBox(pos.yzx-vec3(0.0, 0.0, -0.8), vec3(0.1, 0.5, 0.4));

    // Sphere
    vec3 spos = pos;
    float sphereCell = opRep1(spos.y, 1.1);
    float sphere = sdSphere(spos, 0.5);

    // Cylinder
    vec3 cpos = pos;
    float cylinderCell = opRepMirror2(cpos.xz, vec2(1.0)).x;
    /*cpos += vec3(0.0, 0.25*sin(0.5*(cylinderCell+0.1) * uTime), 0.0);*/
    float cylinder = sdCylinder(cpos+vec3(0.0, 0.2, 0.0), vec2(0.1, 0.5));

    int id = NONE_ID;
    scene = opU(scene, plane, id, PLANE_ID, id);
    scene = opU(scene, box, id, BOX_ID, id);
    scene = opU(scene, sphere, id, SPHERE_ID, id);
    scene = opU(scene, cylinder, id, CYLINDER_ID, id);
    /*scene = opU(scene, opCombine(box, cylinder, 0.04));*/

    hitInfo.id = id;

    if(id == SPHERE_ID) hitInfo.cell.x = sphereCell;
    else if(id == CYLINDER_ID) hitInfo.cell.x = cylinderCell;
    else hitInfo.cell.x = NONE;

    return scene;
}

float map(vec3 pos)
{
    HitInfo _;
    return map(pos, _);
}

// Compute normal by central differences on the distance field at the shading point
// (gradient approximation)
vec3 calcNormal(vec3 pos)
{
	vec3 eps = vec3(0.001, 0.0, 0.0);
	vec3 normal = vec3(
	    map(pos+eps.xyy) - map(pos-eps.xyy),
	    map(pos+eps.yxy) - map(pos-eps.yxy),
	    map(pos+eps.yyx) - map(pos-eps.yyx)
    );
	return normalize(normal);
}

float castRay(
    Ray ray,
    const float tmin, const float tmax,
    const float precis, const int stepmax,
    inout HitInfo hitInfo
)
{
    vec3 ro = ray.origin;
    vec3 rd = ray.direction;
    float t = tmin;
    for(int i = 0; i < stepmax; i++)
    {
	    float d = map(ro + t * rd, hitInfo);
        t += d;
        if(d < precis || t > tmax) break;
    }

    if(t > tmax)  // No hit
    {
        hitInfo.id = -1;
    }
    else // Hit
    {
        // Store hit info
        hitInfo.dist   = t;
        hitInfo.pos    = ro + t * rd;
        hitInfo.normal = calcNormal(hitInfo.pos);
    }

    return t;
}

float softShadows(vec3 ro, vec3 rd, const float mint, const float tmax)
{
	float res = 1.0;
    float t = mint;
    for(int i = 0; i < 50; i++)
    {
		float h = map(ro + t * rd);
        float sharpness = 20.0;
        res = min(res, sharpness * h / t);
        t += clamp(h, 0.02, 0.05);
        if(h < 0.001 || t > tmax) break;
    }
    return clamp(res, 0.0, 1.0);
}


vec3 phong(vec3 pos, vec3 normal, vec3 view, Light light, Material mat)
{
    vec3 l = light.position.xyz;
    float amb = clamp(0.5 + 0.5 * normal.y, 0.0, 1.0);
    float dif = clamp(dot(l, normal), 0.0, 1.0);
    vec3 h = normalize(view + l);
    float spe = pow(clamp(dot(h, normal), 0.0, 1.0), mat.shininess);

    float occ = 1.0;
    #if OCCLUSION
    occ = 0.5 + 0.5 * normal.y;
    #endif

    float shadow = 1.0;
    #if SHADOWS
    shadow = softShadows(pos, l, 0.02, 2.5);
    #endif

    vec3 color = vec3(0.0);
    color += amb * mat.ambient * occ;
    vec3 diffCoeff = light.power * light.color * dif * occ * shadow;
    color += diffCoeff * mat.diffuse;
    color += diffCoeff * spe * mat.specular;

    return color;
}

#include "isolines.glsl"

vec3 raytrace(Ray ray)
{
    vec3 color = vec3(0.0);

    // Cast ray and get intersection info
    HitInfo hitInfo;
    float t = castRay(ray, TMIN, TMAX, PRECISION, STEP_MAX, hitInfo);

    if(hitInfo.id >= 0) // Object hit
    {
        vec3 pos = hitInfo.pos;
        vec3 normal = hitInfo.normal;
        vec3 view = -normalize(ray.direction);

        Material mat;
        #if 0
        mat = uMaterials[hitInfo.id];
        #else
        mat.ambient = vec3(0.05, 0.15, 0.2);
        mat.specular = vec3(1.0, 1.0, 1.0);
        mat.shininess = 128.0;
        if(hitInfo.id == 1)
        {
            mat.diffuse = vec3(1.0, 0.6, 0.8);
        }
        else
        {
            mat.diffuse = vec3(0.2, 0.6, 0.8);
            if(hitInfo.cell.x != NONE)
            {
                mat.diffuse.r = abs(sin(hitInfo.cell.x * 15.0));
                mat.diffuse.g = abs(cos(hitInfo.cell.x * 50.0));
                mat.diffuse.b = abs(cos(mod(hitInfo.cell.x, 0.5) * 305.2));
                mat.shininess = mix(64.0, 128.0, abs(sin(hitInfo.cell.x)));
            }
        }
        #endif

        #if LIGHTING
        // Apply Phong lighting model
        const float lightCount = LIGHT_COUNT;
        for(int i = 0; i < lightCount; ++i)
        {
            Light light = uLights[i];
            color += phong(pos, normal, view, light, mat);
        }
        #else
        color = mat.diffuse;
        #endif

        // Checkerboard floor
        if(hitInfo.id == 0)
        {
            float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
            color = mix(color, vec3(0.2 + 0.1 * f), 0.65);
        }


        #if ISOLINES_DEBUG
        {
            float y = 2.0 * (uMouse.y / uResolution.y) - 1.0;
            vec3 isolines = vec3(0.0);
            if(isolinesDebug(ray, t, y, isolines))
            {
                color = mix(color, isolines, 0.90);
            }
        }
        #endif
    }
    else // Background
    {
        vec2 uv = vTexCoord;
        color = vec3(uv, 0.5 + 0.5 * sin(1.0));
        /*color = vec3(uv, 0.5 + 0.5 * sin(uTime));*/
    }

	return clamp(color, 0.0, 1.0);
}


void main()
{
    // Screen info
    vec2 resolution = uResolution;
    vec2 fragCoord  = gl_FragCoord.xy;

    // Time
    float time = 15.0 + uTime;
    time = 42.0;

    // Mouse
    vec2 mouse = vec2(0.0);
    #if MOUSE
    mouse = uMouse.xy / uResolution.xy;
    #endif

    // Camera
    Camera camera = Camera(vec3(1.0), 1.25, vec3(0.0), 0.0);
    moveCamera(camera, time, mouse, fragCoord, resolution);

    // Ray tracing (sphere tracing)

    vec3 color = vec3(0.0);

    // Multisample antialiasing
    float aa = float(AA_SAMPLES) / 2.0;
    for(int i = 0; i < AA_SAMPLES; i++)
    {
        vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;
        Ray ray = getRay(camera, fragCoord + offset, uResolution);
        color += raytrace(ray); // Cast ray through the scene
    }
	color /= float(AA_SAMPLES);

    #if GAMMA_CORRECTION
    color = pow(color, vec3(0.4545));
    #endif

    // Vignetting
    #if VIGNETTING
    vec2 q = fragCoord.xy / uResolution.xy;
    color *= 0.05 + 1.0 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);
    #endif

    RenderTarget0 = vec4(color, 1.0);
}
