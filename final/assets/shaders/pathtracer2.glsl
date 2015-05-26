#define MULTIPLICITY 1
#define SAMPLES 512
#define MAXDEPTH 8

// Debug to see how many samples never reach a light source
#define DEBUG_NO_HIT 0

// Discard rays that will gather low intensity
#define LOW_INTENSITY_OPTIMIZATION 0
#define INTENSITY_THRESHOLD 0.2

// Use Schlick's approximation for Fresnel effect
#define FRESNEL_SCHLICK 1

#define DEPTH_RUSSIAN 2
#define RUSSIAN_ROULETTE 0

#define PI 3.14159265359
#define DIFF 1
#define SPEC 2
#define REFR 3
//TODO: add emissive material
//TODO: add no shading material
#define EMIS 4
#define NO_SHADING 0


#include "distance_fields.glsl"
#include "fragmentarium/sunsky.glsl"
#include "random.glsl"
#include "ray.glsl"
#include "distributions.glsl"

#include "pathtracer/fresnel.glsl"

#define RAYMARCHING 0
const float NONE = 1e5;
const float PRECISION = 0.0001;
const float TMIN = 10.0 * PRECISION;
const float TMAX = 1000.0;
const int STEP_MAX = 500;


float seed = 0.0;
vec2 SEED = vec2(0.0);

float rand()
{
    /*SEED += vec2(0.1, -0.1);*/
    /*return hash2(SEED);*/
    return fract(sin(seed++)*43758.5453123);
}

struct Light
{
    vec3 pos;
    float radius;
    vec3 color;
    float power;
};

const int LIGHT_COUNT = 2;
uniform Light uLights[LIGHT_COUNT] = Light[](
    Light(vec3(155.0, 22., 30.6), 10.0, vec3(0.8, 1.5, 0.3), 13.0)
    ,
    Light(vec3(50.0, 81.6, 81.6), 20.0, vec3(1.0), 3.0)
);

int lightCount = 0;


struct Material
{
	float type;
    vec3  color;
    vec3  emissive;
    // TODO: add roughness
    /*float roughness;*/
};

struct Sphere
{
	float radius;
	vec3 pos;
    Material material;
};

struct HitInfo
{
    Sphere obj;
    int id;
    vec3 pos;
    vec3 normal;
    float dist;
};


const vec3 white  = vec3(1.0);
const vec3 black  = vec3(0.0);
const vec3 gray   = vec3(0.75);
const vec3 red    = vec3(0.75, 0.25, 0.25);
const vec3 green  = vec3(0.25, 0.75, 0.25);
const vec3 blue   = vec3(0.25, 0.25, 0.75);
const vec3 yellow = vec3(0.75, 0.75, 0.25);
const vec3 lgreen = vec3(0.7, 1.0, 0.9);
const vec3 lblue  = vec3(0.7, 0.8, 0.9);

#define NUM_SPHERES 5
Sphere spheres[NUM_SPHERES] = Sphere[](
    // Red wall
    /*Sphere(1e5, vec3(-1e5+1., 40.8, 81.6), Material(DIFF, red, black)),*/

    // Blue wall
    /*Sphere(1e5, vec3( 1e5+99., 40.8, 81.6), Material(DIFF, blue, black)),*/

    // Front wall
    /*Sphere(1e5, vec3(50., 40.8, -1e5), Material(DIFF, gray, black)),*/

    // Back wall
    /*Sphere(1e5, vec3(50., 40.8,  1e5+170), Material(DIFF, green, black)),*/

    // Floor
    Sphere(1e5, vec3(50., -1e5, 81.6), Material(DIFF, white, black)),

    // Ceiling
    /*Sphere(1e5, vec3(50.,  1e5+81.6, 81.6), Material(DIFF, gray, black)),*/

    // Plastic ball
	Sphere(8.5, vec3(45., 8.5, 78.), Material(DIFF, red, black)),

    // Metallic ball
	Sphere(16.5, vec3(27., 16.5, 47.), Material(SPEC, yellow, black)),

    // Glass ball
	Sphere(16.5, vec3(73., 16.5, 78.), Material(REFR, lblue, black))


    // First light
    /*Sphere(600., vec3(50., 681.33, 81.6), 2.0*white, black, DIFF)*/
    /*,Sphere(uLights[0].radius, uLights[0].pos, Material(DIFF, black, uLights[0].power*uLights[0].color))*/
    ,Sphere(uLights[0].radius, uLights[0].pos, Material(DIFF, uLights[0].color, uLights[0].color))

    // Second light
    /*,Sphere(uLights[1].radius, uLights[1].pos, Material(DIFF, black, 2.0*uLights[1].color)))*/
);

#define RANDOM_SAMPLING 1
#if RANDOM_SAMPLING

vec3 ortho(vec3 v) {
	//  See : http://lolengine.net/blog/2013/09/21/picking-orthogonal-vector-combing-coconuts
	return abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0)  : vec3(0.0, -v.z, v.y);
}

vec3 getConeSample(vec3 dir, float extent)
{
	// Create orthogonal vector(fails for z,y = 0)
	dir = normalize(dir);
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));

	// Convert to spherical coords aligned to dir
	vec2 r =  hash2(vec2(seed-1.0, seed++));

	/*if(Stratify) {r*=0.1; r+= cx;}*/
	r.x=r.x*2.*PI;
	r.y=1.0-r.y*extent;

	float oneminus = sqrt(1.0-r.y*r.y);
	return cos(r.x)*oneminus*o1+sin(r.x)*oneminus*o2+r.y*dir;
}
#endif


float distance(Sphere s, Ray ray)
{
    const float EPSILON = 1e-3;
	vec3 op = s.pos - ray.origin;
    float b = dot(op, ray.direction);
    float det = b * b - dot(op, op) + s.radius * s.radius;

	float t;
	if(det < 0.0) // No intersection
    {
        return 0.0;
    }
    else
    {
        det = sqrt(det);
    }

	return (t = b - det) > EPSILON ? t : ((t = b + det) > EPSILON ? t : 0.0);
}

bool raytrace(Ray ray, int avoid, out HitInfo hitInfo)
{
	hitInfo.id   = -1;
    hitInfo.dist = 1e5;

    Sphere hit;
	for(int i = 0; i < NUM_SPHERES; ++i)
    {
        if(i == avoid) continue;

		Sphere s = spheres[i];
		float d = distance(s, ray);
		if(d != 0.0 && d < hitInfo.dist)
        {
            hit = s;
            hitInfo.dist = d;
            hitInfo.id = i;
        }
	}

    // The closest intersection has been found
    if(hitInfo.id != -1)
    {
        hitInfo.pos    = ray.origin + hitInfo.dist * ray.direction;
        hitInfo.normal = normalize(hitInfo.pos - hit.pos);
        return true;
    }

    return false;
}

float distance(Light light, Ray ray)
{
    const float EPSILON = 1e-3;
    const float INF = 1e5;
	vec3 op = light.pos - ray.origin;
    float b = dot(op, ray.direction);
    float det = b * b - dot(op, op) + light.radius * light.radius;

	float t;
	if(det < 0.0) // No intersection
    {
        return INF;
    }
    else
    {
        det = sqrt(det);
    }

	return (t = b - det) > EPSILON ? t : ((t = b + det) > EPSILON ? t : INF);
}

vec3 jitter(vec3 d, float phi, float sina, float cosa)
{
    /*return rHemisphereUniform(SEED);*/
	vec3 w = normalize(d);
    vec3 u = normalize(cross(w.yzx, w));
    vec3 v = cross(w, u);
	return (u * cos(phi) + v * sin(phi)) * sina + w * cosa;
}


float map(vec3 p, inout HitInfo hitInfo)
{
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

bool DirectLight = true;



vec3 background(Ray ray, int depth, vec3 direct, inout vec3 color)
{
    if(!DirectLight)
    {
        return color * sunsky(ray.direction);
    }
    else
    {
        return direct + color * (depth > 0 ? sky(ray.direction) : sunsky(ray.direction));
    }
}

bool raymarch(
    Ray ray,
    const float tmin, const float tmax,
    const float precis, const int stepmax,
    inout HitInfo hitInfo
)
{
    vec3 ro = ray.origin;
    vec3 rd = ray.direction;
    float t = tmin;

    hitInfo.id = -1;

    // Raymarching using "sphere" tracing
    for(int i = 0; i < stepmax; i++)
    {
        float d = map(ro + t * rd, hitInfo);
        t += abs(d);
        if(abs(d) < precis || t > tmax) break;
    }

    // No hit
    if(t > tmax)
    {
        hitInfo.id = -1;
        return false;
    }
    else
    {
        // Store hit info
        hitInfo.dist   = t;
        hitInfo.pos    = ro + t * rd;
        hitInfo.normal = calcNormal(hitInfo.pos);
        return true;
    }
}

Material getMaterial(HitInfo hitInfo)
{
    int id = hitInfo.id;
    vec3 pos = hitInfo.pos;

    #if RAYMARCHING
    Material mat;
    mat.type = DIFF;
    mat.color = vec3(1.0);
    mat.emissive = vec3(0.0);

    // Checkerboard floor
    if(id == 0)
    {
        mat.type = DIFF;
        float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
        mat.color = vec3(0.02 + 0.1 * f) * 10.5;
        /*mat.color = mix(color, vec3(0.2 + 0.1 * f), 0.65);*/
    }
    else if(id == 1)
    {
        mat.type = SPEC;
        mat.color = vec3(1.0);//vec3(0.9, 0.5, 0.4);
    }
    else if(id == 2)
    {
        mat.type = DIFF;
        mat.color = vec3(1.0, 1.0, 1.0);
        mat.color = vec3(1.0, 0.0, 1.0);
    }
    else if(id == 3)
    {
        mat.type = DIFF;
        mat.color = vec3(1.0, 1.0, 1.0);
        mat.emissive = vec3(0.8, 1.5, 0.3);
    }

    return mat;
    #else
    return spheres[id].material;
    #endif
}

Ray BRDFNextRay(
    Ray ray,
    HitInfo hitInfo,
    float depth,
    inout vec3 color,
    inout vec3 mask,
    inout vec3 direct,
    inout vec3 C_O_L_O_R
)
{
    vec3 hit = hitInfo.pos;
    vec3 n   = hitInfo.normal;

    Material mat = getMaterial(hitInfo);

    // Diffuse material
    if(mat.type == DIFF)
    {
        C_O_L_O_R *= mat.color;

        // Make sure the normal of the surface points in the opposite direction
        // of the ray (in case we are inside the surface)
        vec3 normal = n * sign(-dot(n, ray.direction));

        // Check if current object is visible to any lights
        vec3 lightIntensity = vec3(0.0);
        #if 0
        for(int i = 0; i < lightCount; ++i)
        {
            Light light = uLights[i];

            // Vector hit-light
            vec3 lightDir = light.pos - hit;
            float r2 = light.radius * light.radius;

            // Cosine of the maximum angle to reach the light (cone of light rays)
            float cosAMax = sqrt(1.0 - clamp(r2 / dot(lightDir, lightDir), 0.0, 1.0));

            // Random cosine inside the cone of light
            float cosa = mix(cosAMax, 1.0, rand());

            // Light direction: random vector in the cone of light
            vec3 l = jitter(lightDir, 2.0 * PI * rand(), sqrt(1.0 - cosa * cosa), cosa);

            // Shadow ray
            Ray shadowRay = Ray(hit, l);

            HitInfo shadowingInfo;

            // Check if the current hit point is potentially shadowed
            #if RAYMARCHING
            bool ps = raymarch(shadowRay, TMIN, TMAX, PRECISION, STEP_MAX, shadowingInfo);
            #else
            bool ps = raytrace(shadowRay, hitInfo.id, shadowingInfo);
            #endif

            float t = shadowingInfo.dist;

            // FIXME: not correct because refractive can block light completely
            bool intersection;
            float lightDist = distance(light, shadowRay);
            // FIXME: intersection should always be true (the shadowRay is aimed towards the light)
            if(intersection && lightDist < t)
            {
                vec3 I = light.power * light.color * clamp(dot(l, n), 0.0, 1.0);
                float omega = 2.0 * PI * (1.0 - cosAMax);
                lightIntensity += (I * omega) / PI;
            }
        }
        #endif

        float Albedo = 1.0;


        #if 1
        //TODO: think if this must be done before lights contributions
        // New ray direction: random vector on the normal-oriented hemisphere
        float r2 = rand();
        vec3 d = jitter(normal, 2.0 * PI * rand(), sqrt(r2), sqrt(1.0 - r2));

        C_O_L_O_R *= 2.0 * Albedo * max(0.0, dot(d, normal));

        /*if(hitInfo.normal != normal)*/
        /*{*/
            /*C_O_L_O_R = 10000.0;*/
        /*}*/
        #else
        vec3 d;
        if(BiasSampling)
        {
            // Biased sampling: cosine weighted
            // Lambertian BRDF = Albedo / PI
            // PDF = cos(angle) / PI
            d = getBiasedSample(normal, 1.0);

            // Modulate color with: BRDF * cos(angle) / PDF = Albedo
            C_O_L_O_R *= Albedo;
        }
        else
        {
            // Unbiased sampling: uniform over normal-oriented hemisphere
            // Lambertian BRDF = Albedo / PI
            // PDF = 1 / (2 * PI)
            d = getHemisphereSample(normal, 1.0);

            // Modulate color with: BRDF * cos(angle) / PDF = 2 * Albedo * cos(angle)
            C_O_L_O_R *= 2.0 * Albedo * max(0.0, dot(d, normal));
        }
        #endif


        // Direct sun light
        if(DirectLight)
        {
            vec3 sunSampleDir = getConeSample(sunDirection, 1.0-sunAngularDiameterCos);
            float sunLight = dot(normal, sunSampleDir);

            if(sunLight > 0.0)
            {
                Ray shadowRay = Ray(hit, sunSampleDir);
                HitInfo _;

                #if RAYMARCHING
                if(!raymarch(shadowRay, TMIN, TMAX, PRECISION, STEP_MAX, _))
                #else
		        if(!raytrace(shadowRay, hitInfo.id, _))
                #endif
                {
                    direct += C_O_L_O_R * sun(sunSampleDir) * sunLight * 1E-5;
                }
            }
        }

        // TODO: Lights: two approaches
        // - indirect using the emissive property of the material
        //  (the light color and power is encoded into the emissive color)
        //  -> the emissive value is queried as intensity for lights
        // - direct using extra rays sent towards the emitters
        //  -> the material of the lights must not be emissive to avoid
        //     gathering the emitted energy twice
        //     However, non explicit emitters can still exists with the
        //     emissive color of their materials
        //
        // => only gather emissive quantity of the first bounce?
        /* float E = float(depth == 0);*/

        float E = 1.0;

        direct += C_O_L_O_R * mat.emissive * E;

        color += mask * mat.emissive * E;
        color += mask * mat.color * lightIntensity;
        mask *= mat.color;

        ray = Ray(hit, d);
    }
    // Specular (reflective) material
    else if(mat.type == SPEC)
    {
        color += mask * mat.emissive;
        mask *= mat.color;
        ray = Ray(hit, reflect(ray.direction, n));

        C_O_L_O_R *= mat.color;
        /*C_O_L_O_R *= max(0.0, dot(ray.direction, normal));*/
    }
    // Refractive material
    else
    {
        // Refractive indices
        // n1: air, n2: glass
        float n1 = 1.0, n2 = 1.5;

        // n is the normal vector that points from the surface towards its outside.
        // NoL is positive if the ray is coming from the inside of the surface
        // (negative side) and negative if it is coming from the outside.
        float NoL = dot(n, ray.direction);

        // Relative position from the refractive material:
        // 0: outside, 1: inside
        float inside = float(NoL > 0.0);

        // Cosine of the angle of incidence: must be positive for the Snell's law
        float cosTheta1 = abs(NoL);

        // Ratio of refractive indices
        float r = mix(n1 / n2, n2 / n1, inside);

        // Snell's law
        // http://en.wikipedia.org/wiki/Snell%27s_law#Derivations_and_formula
        float cosTheta2 = 1.0 - r * r * (1.0 - cosTheta1 * cosTheta1);

        // If no total internal reflection
        // => total internal reflection <-> cosTheta2 <= 0.0
        // http://en.wikipedia.org/wiki/Total_internal_reflection
        if(cosTheta2 > 0.0)
        {
            // /!\ The light path is inverted in path tracing.
            // For this reason, we arrive either from the reflection or
            // refraction side, and not the incident one.
            // This is not an issue because the propagation is reversible.


            // Direction of incidence of light (surface -> light source)
            vec3 refl = reflect(ray.direction, n);

            // Refraction direction
            vec3 refr = r * refl + (r * cosTheta1 + sqrt(cosTheta2)) * n * sign(NoL);
            refr = normalize(refr);


            // Reflection and transmission coefficients
            // and reflection probability
            float R, T, P;

            #if FRESNEL_SCHLICK
            // Reflection coefficient at normal incidence
            float R0 = pow((n1 - n2) / (n1 + n2), 2.0);

            // cos(theta) = H.L
            float HoL = mix(cosTheta1, dot(refr, n), inside);

            // Fresnel: Schlick approximation
            P = fresnelSchlick(R0, HoL, R, T);
            #else
            // Fresnel: artist approximation
            P = fresnelApprox(NoL, R, T);
            #endif

            // Split ray: reflection + refraction
            if(rand() < P) // Reflection
            {
                mask *= /*mat.color **/ R;
                C_O_L_O_R *= mat.color * R;
                ray = Ray(hit, refl);
            }
            else // Refraction
            {
                mask *= mat.color * T;
                C_O_L_O_R *= mat.color * T;// * max(0.0, dot(ray.direction, -n));
                ray = Ray(hit, refr);
            }
        }
        else
        {
            vec3 refl = reflect(ray.direction, n);
            ray = Ray(hit, refl);
        }
    }

    return ray;
}

vec3 radiance(Ray ray)
{
	vec3 color  = vec3(0.0);
	vec3 direct = vec3(0.0);
	vec3 mask   = vec3(1.0);

    HitInfo hitInfo;
	hitInfo.id = -1;

	vec3 C_O_L_O_R  = vec3(1.0);

	for(int depth = 0; depth < MAXDEPTH; ++depth)
    {
        // If the mask is too low, the intensity gather
        // by the subsequent rays won't contribute much
        #if LOW_INTENSITY_OPTIMIZATION
        const vec3 MASK_THRESHOLD = vec3(INTENSITY_THRESHOLD);
        if(all(lessThan(mask, MASK_THRESHOLD))) break;
        #endif

        // If no hit, get background color and exit
        #if RAYMARCHING
        if(!raymarch(ray, TMIN, TMAX, PRECISION, STEP_MAX, hitInfo))
        #else
        if(!raytrace(ray, hitInfo.id, hitInfo))
        #endif
        {
            return background(ray, depth, direct, C_O_L_O_R);
        }

        // Compute lighting contribution and outgoing ray
        ray = BRDFNextRay(ray, hitInfo, depth, color, mask, direct, C_O_L_O_R);
	}

    return direct;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    float time = uTime;
    time = 42.0;

	seed = time + uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

	vec2 uv = 2. * fragCoord.xy / uResolution.xy - 1.;

    vec2 mo = (2.0 * (uMouse.xy == vec2(0.0) ? 0.5 * uResolution.xy : uMouse.xy) / uResolution.xy - 1.0);
	vec3 camPos = vec3(mo * vec2(48., 40.) + vec2(50., 40.8), 169.);

	vec3 cz = normalize(vec3(50., 40., 81.6) - camPos);
	vec3 cx = vec3(1., 0., 0.);
	vec3 cy = normalize(cross(cx, cz)); cx = cross(cz, cy);
	vec3 color = vec3(0.);

    vec2 pixel = fragCoord;
    vec2 resolution = uResolution;

    for(int k = 0; k < MULTIPLICITY; ++k)
    {
        float npaths = SAMPLES;
        float aa = float(npaths) / 2.0;
        for(int i = 0; i < npaths; ++i)
        {
            vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;

            SEED = pixel + offset;

            // Screen coords with antialiasing
            vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;

            #if DEBUG_NO_HIT
            vec3 test = radiance(Ray(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz)));
            if(dot(test, test) > 0.0) color += vec3(1.0); else color += vec3(0.5, 0.0, 0.1);
            #else
            color += radiance(Ray(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz)));
            #endif
        }
        color /= float(npaths);
    }

	fragColor = vec4(pow(clamp(color, 0., 1.), vec3(1./2.2)), 1.);
}
