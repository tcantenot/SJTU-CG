#version 140

#include "primitives.glsl"
#include "operators.glsl"

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse = vec4(0.0);

out vec4 RenderTarget0;

#define ANTI_ALIASING 1
#define AA_SAMPLES 4

#define GAMMA_CORRECTION 1
#define VIGNETTING 0


const float NONE = 1e20;

struct Light
{
    vec3 direction;
    vec3 position;
    vec3 color;
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
    float cell;
    vec3 normal;
    float dist;
    //vec3 uvw;
};

const int NONE_ID     = -1;
const int PLANE_ID    = 0;
const int BOX_ID      = 1;
const int SPHERE_ID   = 2;
const int CYLINDER_ID = 3;

const Material materials[] = Material[]
(
    Material(vec3(0.2), vec3(0.2, 0.8, 0.7), vec3(1.0), 64.0),
    Material(vec3(0.2), vec3(0.5, 0.9, 0.5), vec3(1.0), 100.0),
    Material(vec3(0.2), vec3(0.5, 0.5, 0.9), vec3(1.0), 128.0),
    Material(vec3(0.2), vec3(0.5, 0.3, 0.0), vec3(1.0), 16.0)
);



float map(vec3 pos, inout HitInfo hitInfo)
{
    float scene = NONE;

    // Plane
    float plane = sdPlaneY(pos+vec3(0, 2, 0));

    // Box
    float box = sdBox(pos.yzx-vec3(0.0, 0.0, -0.8), vec3(0.1, 0.5, 0.4));

    // Sphere
    vec3 spos = pos;
    float sphereCell = opRep1(spos.y, 1.1);
    float sphere = sdSphere(spos, 0.5);

    // Cylinder
    vec3 cpos = pos;
    float cylinderCell = opRep1(cpos.z, 1.0);
    float cylinder = sdCylinder(cpos, vec2(0.1, 0.3));

    int id = NONE_ID;
    scene = opU(scene, plane, id, PLANE_ID, id);
    scene = opU(scene, box, id, BOX_ID, id);
    scene = opU(scene, sphere, id, SPHERE_ID, id);
    scene = opU(scene, cylinder, id, CYLINDER_ID, id);
    /*scene = opU(scene, opCombine(box, cylinder, 0.04));*/

    hitInfo.id = id;

    if(id == SPHERE_ID) hitInfo.cell = sphereCell;
    else if(id == CYLINDER_ID) hitInfo.cell = cylinderCell;
    else hitInfo.cell = NONE;

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
    vec3 ro, vec3 rd,
    const float tmin, const float tmax,
    const float precis, const int stepmax,
    inout HitInfo hitInfo
)
{
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

float softshadow(vec3 ro, vec3 rd, const float mint, const float tmax)
{
	float res = 1.0;
    float t = mint;
    for(int i = 0; i < 16; i++)
    {
		float h = map(ro + t * rd);
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.10);
        if(h < 0.001 || t > tmax) break;
    }
    return clamp(res, 0.0, 1.0);
}


vec3 phong(vec3 pos, vec3 normal, vec3 view, vec3 light, Material mat)
{
    float amb = clamp(0.5 + 0.5 * normal.y, 0.0, 1.0);
    float dif = clamp(dot(light, normal), 0.0, 1.0);
    vec3 h = normalize(view + light);
    float spe = pow(clamp(dot(h, normal), 0.0, 1.0), mat.shininess);
    float occ = 0.5 + 0.5 * normal.y;

    float shadow = softshadow(pos, light, 0.02, 2.5);

    vec3 color = vec3(0.0);
    color += amb * mat.ambient * occ;
    color += dif * mat.diffuse * occ * shadow;
    color += dif * spe * mat.specular * occ;

    return color;
}

vec3 render(in vec3 ro, in vec3 rd)
{
    const float PRECIS = 0.0001;
    const float TMIN = 0.1;
    const float TMAX = 50.0;
    const int STEP_MAX = 500;

    HitInfo hitInfo;

    float t = castRay(ro, rd, TMIN, TMAX, PRECIS, STEP_MAX, hitInfo);

    vec3 color = vec3(0.8, 0.9, 1.0);
    color = vec3(0.0);

    float rayLength = t;

    if(hitInfo.id >= 0)
    {
        vec3 pos = hitInfo.pos;
        vec3 normal = hitInfo.normal;
        vec3 view   = -normalize(rd);
        vec3 light  = normalize(vec3(-0.6, 0.7, -0.5));

        Material mat;
        #if 0
        mat = materials[hitInfo.id];
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
            if(hitInfo.cell != NONE)
            {
                mat.diffuse.r = abs(sin(hitInfo.cell * 15.0));
                mat.diffuse.g = abs(cos(hitInfo.cell * 50.0));
                mat.diffuse.b = abs(cos(mod(hitInfo.cell, 0.5) * 305.2));
                mat.shininess = mix(64.0, 128.0, abs(sin(hitInfo.cell)));
            }
        }
        #endif

        color = phong(pos, normal, view, light, mat);

        // Checkboard floor
        if(hitInfo.id == 0)
        {

            float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
            color = 0.4 + 0.1 * f * vec3(1.0);
        }

    // Test ray with isolinesPlane:
#define DEBUG_MODE 1
#if DEBUG_MODE == 1

        float isolinesPlane = 0.0;//(uMouse.y / uResolution.y - 0.1) * 8.0;

        isolinesPlane = max(0.0, isolinesPlane);
        if(rd.y * sign(ro.y - isolinesPlane) < 0.0)
        {
            float d = (ro.y - isolinesPlane) / -rd.y;
            if(d < rayLength)
            {
                vec3 hit = ro + d * rd;
                float hitDist = map(hit);
                float iso = fract(hitDist * 5.0);

                vec3 lhs = vec3(.2,.4,.6);
                vec3 rhs = vec3(.2,.2,.4);
                /*lhs = vec3(.5, 0.0, 0.0);*/
                /*rhs = vec3(1.0, 0.0, 0.0);*/
                vec3 dist_color = mix(lhs, rhs, iso);

                dist_color *= 1.0 / (max(0.0, hitDist) + 0.001);
                /*dist_color = min(vec3(1.0,1.0,1.0),dist_color);*/
                color = mix(color,dist_color, 0.25);
                /*color = dist_color;*/
                rayLength = d;
            }
        }
#endif
    }
    else // Background
    {
        /*vec2 uv = vTexCoord;*/
		/*color = vec3(uv, 0.5 + 0.5 * sin(uTime));*/
    }

	return clamp(color, 0.0, 1.0);
}

mat3 setCamera(vec3 eye, vec3 target, float cr)
{
	vec3 cw = normalize(target - eye);
	vec3 cp = vec3(sin(cr), cos(cr), 0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

mat3 lookat( in vec3 fw, in vec3 up )
{
	fw = normalize(fw);
	vec3 rt = normalize( cross(fw, normalize(up)) );
	return mat3( rt, cross(rt, fw), fw );
}

vec3 scene(vec3 ro, vec3 rd)
{
    vec3 color = render(ro, rd);

    #if GAMMA_CORRECTION
    color = pow(color, vec3(0.4545));
    #endif

    return color;
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    float aspect = uResolution.x / uResolution.y;

	vec2 q = fragCoord.xy / uResolution.xy;
    vec2 p = q * 2.0 - 1.0;
	p.x *= aspect;

    vec2 mo = uMouse.xy / uResolution.xy;
    mo = vec2(0.0);

	float time = 15.0 + uTime;
    time = 42.0;

	// Camera
	vec3 eye = vec3(
        -0.5 + 3.2 * cos(0.1 * time + 6.0 * mo.x),
        1.0 + 2.0 * mo.y,
        0.5 + 3.2 * sin(0.1 * time + 6.0 * mo.x)
    );

	vec3 target = vec3(-0.5, -0.4, 0.5);

    /*eye = vec3(0.0, 10.0, -15.0);*/
    target = vec3(0.0, 0.0, 0.0);

	// Camera-to-World matrix
    mat3 cam = setCamera(eye, target, 0.0);

    // Ray origin and direction
    float focal = 1.25;
    vec3 ro = eye;

    vec3 color = vec3(0.0);

    #if ANTI_ALIASING
    for(int i = 0; i < AA_SAMPLES; i++)
    {
        vec2 offset = vec2(
            mod(float(i), float(AA_SAMPLES)/2.0),
            mod(float(i/2), float(AA_SAMPLES)/2.0)
        ) / (float(AA_SAMPLES) / 2.0);
    #else
        vec2 offset = vec2(0.0);
    #endif


        vec3 rd = vec3(0.0);
        {
            vec2 q = (fragCoord.xy + offset) / uResolution.xy;
            vec2 p = q * 2.0 - 1.0;
            p.x *= aspect;
	        rd = cam * normalize(vec3(p.xy, focal));
        }

        // Render scene
        color += scene(ro, rd);
    #if ANTI_ALIASING
    }
	color /= float(AA_SAMPLES);
    #endif

    #if VIGNETTING
    vec2 q = fragCoord.xy / uResolution.xy;
    color *= 0.2 + 0.8 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);
    #endif

    RenderTarget0 = vec4(color, 1.0);
}
