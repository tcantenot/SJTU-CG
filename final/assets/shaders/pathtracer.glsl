#include "camera.glsl"
#include "distance_fields.glsl"
#include "distributions.glsl"
#include "hitinfo.glsl"
#include "random.glsl"
#include "ray.glsl"

vec2 SEED = vec2(0.0);

const float NONE = 1e20;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
const float TMAX = 1000.0;
const int STEP_MAX = 500;

uniform vec3 uSunDirection = -vec3(1.0, -10.0, -1.0);
uniform vec3 uSunColor = vec3(2.0, 1.6, 1.0) / 2.0;
uniform vec3 uSkyColor = vec3(0.7, 0.8, 0.9);

#define DOF 0
const int NPATHS = 4;

vec3 SUN = uSunDirection;

float RANDOM_1F(vec2 seed)
{
    return hash(seed);
}

vec2 RANDOM_2F(vec2 seed)
{
    return hash2(seed);
}

// See TotalCompendium
vec2 DISK_POINT(vec2 seed)
{
    return rDiskConcentric(seed);
}

vec3 COSINE_DIRECTION(vec2 seed)
{
    return rHemisphereCosine(seed);
}

vec3 CONE_DIRECTION(float angle, vec2 seed)
{
    return rHemisphereCosine(angle, seed);
}

float WORLD_SHADOW(vec3 pos, vec3 light);

vec3 WORLD_GET_BACKGROUND(vec3 rd)
{
#if 0
    vec3 light = SUN;
    float sun = max(0.0, dot(rd, light));
    float sky = max(0.0, dot(rd, vec3(0.0, 1.0, 0.0)));
    float ground = max(0.0, -dot(rd, vec3(0.0, 1.0, 0.0)));
    return
        (pow(sun, 256.0)+0.2*pow(sun, 2.0))*vec3(2.0, 1.6, 1.0) +
        pow(ground, 0.5)*vec3(0.4, 0.3, 0.2) +
        pow(sky, 1.0)*vec3(0.5, 0.6, 0.7);
#else
    vec2 uv = vTexCoord.xy;
    return vec3(uv, 0.5 + 0.5 * sin(uTime));
#endif
}

vec3 WORLD_GET_COLOR(vec3 pos, vec3 normal, int id)
{
    // Checkerboard floor
    if(id == 0)
    {
        float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
        return vec3(0.02 + 0.1 * f);
        /*color = mix(color, vec3(0.2 + 0.1 * f), 0.65);*/
    }
    else if(id == 1) return vec3(0.9, 0.5, 0.4);
    else if(id == 2) return vec3(1.0, 1.0, 1.0);
    else if(id == 3) return vec3(0.0, 1.0, 1.0);

    return vec3(1.0);
}


void WORLD_MOVE_OBJECTS(float time)
{
    SUN = normalize(vec3(sin(time), 0.6, cos(time)));
}

mat4x3 WORLD_MOVE_CAMERA(float time);

vec3 WORLD_APPLYING_LIGHTING(vec3 pos, vec3 normal)
{
    vec3 dcol = vec3(0.2);

    vec2 seed = gl_FragCoord.xy + pos.xz;
    seed = SEED;

    mat3 tbn = randomTBN(normal, seed);

    // Sample sun
    /*if(false)*/
    {
        vec3 lightDir = SUN;
        /*lightDir = uSunDirection;*/
        vec3  point = 1000.0 * lightDir;
        point += 50.0 * tbn * COSINE_DIRECTION(seed);//vec3(DISK_POINT(seed), point.z);
        vec3  light = normalize(point - pos);
        float NoL =  max(0.0, dot(normal, light));
        dcol += NoL * uSunColor * 1.0; //WORLD_SHADOW(pos, light);
    }

    // Sample sky
    if(false)
    {
        vec3  point = 1000.0 * tbn * COSINE_DIRECTION(seed);
        vec3  light = normalize(point - pos);
        dcol += uSkyColor * 1.0; //WORLD_SHADOW(pos, light);
    }

    return dcol;
}

vec3 WORLD_GET_BRDF_RAY(in vec3 pos, in vec3 normal, in vec3 eye, in int materialID)
{
    vec2 seed = gl_FragCoord.xy + pos.xy;
    seed = SEED;

    /*return reflect(eye, normal);*/

    float diffuse = 0.0;
    float roughness = 0.0;


    if(materialID == 1)
    {
        diffuse = 0.0;
        roughness = 0.2;
    }
    else if(materialID == 3)
    {
        diffuse = 1.0;
    }

    if(RANDOM_1F(seed) < diffuse)
    {
        mat3 tbn = randomTBN(normal, seed);
        return tbn * COSINE_DIRECTION(seed);
    }
    else
    {
        vec3 r = reflect(eye, normal);
        mat3 tbn = randomTBN(r, seed);
        return tbn * CONE_DIRECTION(roughness, seed);
    }
}

float map(vec3 p, inout HitInfo hitInfo)
{
    float scene = NONE;

    int id = -1;

    float plane = sdPlaneY(p+vec3(0.0, 1.0, 0.0));
    opRep1(p.x, 4);
    opRep1(p.z, 3);
    float sphere = sdSphere(p+vec3(0.1, 0.2, 1.0), 0.5);
    float box = sdBox(p+vec3(1.2, 0.0, 0.0), vec3(0.5));
    float capsule = sdHexPrism(p-vec3(0.0, -0.3, 0.0), vec2(0.1, 0.2));

    scene = opU(scene, plane, id, 0, id);
    scene = opU(scene, sphere, id, 1, id);
    scene = opU(scene, box, id, 2, id);
    scene = opU(scene, capsule, id, 3, id);

    hitInfo.id = id;

    return scene;
}

float map(vec3 p)
{
    HitInfo _;
    return map(p, _);
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

    // Raymarching using sphere tracing
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
    else
    {
        // Store hit info
        hitInfo.dist   = t;
        hitInfo.pos    = ro + t * rd;
        hitInfo.normal = calcNormal(hitInfo.pos);
    }

    return t;
}

vec3 RENDERER_CALCULATE_COLOR(Ray ray, int numLevels)
{
    vec3 tcol = vec3(0.0);
    vec3 fcol = vec3(1.0);

    // Create numLevels light paths iteratively
    for(int i = 0; i < numLevels; i++)
    {
        HitInfo hitInfo;
        float t = castRay(ray, TMIN, TMAX, PRECISION, STEP_MAX, hitInfo);

        int id = hitInfo.id;

        // If nothing found, return background color or break
        if(id < 0)
        {
            if(i == 0)
            {
                fcol = WORLD_GET_BACKGROUND(ray.direction);
                tcol += fcol;
            }

            break;
        }

        // Get position and normal at the intersection point
        vec3 pos    = hitInfo.pos;
        vec3 normal = hitInfo.normal;

        // Get color for the surface
        vec3 scol = WORLD_GET_COLOR(pos, normal, id);

        // Compute direct lighting
        vec3 dcol = WORLD_APPLYING_LIGHTING(pos, normal);

        // Prepare ray for indirect lighting gathering
        ray.origin    = pos;
        ray.direction = normalize(WORLD_GET_BRDF_RAY(pos, normal, ray.direction, id));

        // surface * lighting
        fcol *= scol;
        tcol += fcol * dcol;
    }

    return tcol;
}

// compute the color of a pixel
vec3 CALC_PIXEL_COLOR(vec2 pixel, vec2 resolution, float frameTime)
{
    const float shutterAperture = 0.6;
    const float fov = 2.5;
    const float focusDistance = 1.3;
    const float blurAmount = 0.0015;
    const int   numLevels = 5;

    // Paths per pixel
    const int npaths = NPATHS;
    vec3 color = vec3(0.0);

    float aa = float(npaths) / 2.0;
    for(int i = 0; i < npaths; i++)
    {
        vec2 seed = vec2(float(i), float(i+1));

        vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;

        SEED = pixel + offset;
        seed = SEED;

        // Screen coords with antialiasing
        /*vec2 p = (2.0 * (pixel + RANDOM_2F(seed)) - resolution) / resolution.y;*/
        vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;
        /*vec2 p = (pixel * 2.0 - resolution) / resolution.y;*/

        // Motion blur
        float ctime = frameTime + shutterAperture * (1.0 / 24.0) * RANDOM_1F(seed);

        // Move objects
        //TODO
        /*WORLD_MOVE_OBJECTS(ctime);*/

        // Get camera position, and right/up/front axis
        /*vec3 (ro, uu, vv, ww) = WORLD_MOVE_CAMERA(ctime);*/
        vec3 ro = vec3(2.0);
        vec3 target = vec3(0.0);
        mat3 cam = lookAt(ro, target, 0.0);
        vec3 uu = cam[0];
        vec3 vv = cam[1];
        vec3 ww = cam[2];

        // Create ray with depth of field
        vec3 er = normalize(vec3(p.xy, fov));
        vec3 rd = cam * er;

        #if DOF
        vec3 go = blurAmount * vec3(2.0 * RANDOM_2F(seed) - 1.0, 0.0);
        vec3 gd = normalize(er * focusDistance - go);
        ro += go.x * uu + go.y * vv;
        rd += gd.x * uu + gd.y * vv;
        #endif

        rd = normalize(rd);

        Ray ray = Ray(ro, rd);

        // Accumulate path
        color += RENDERER_CALCULATE_COLOR(ray, numLevels);
    }
    color = color / float(npaths);

    // Apply gamma correction
    color = pow(color, vec3(0.45));

    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 color = CALC_PIXEL_COLOR(fragCoord, uResolution, uTime);
    fragColor = vec4(color, 1.0);
}
