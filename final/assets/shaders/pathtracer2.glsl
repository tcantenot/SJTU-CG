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
#define DIFF 0
#define SPEC 1
#define REFR 2


#include "distance_fields.glsl"
#include "fragmentarium/sunsky.glsl"
#include "random.glsl"
#include "ray.glsl"
#include "distributions.glsl"

#define RAYMARCHING 0
const float NONE = 1e20;
const float PRECISION = 0.0001;
const float TMIN = 0.1;
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

#define NUM_SPHERES 4
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

    // Metallic ball
	Sphere(16.5, vec3(27., 16.5, 47.), Material(SPEC, gray, black)),

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


float intersect(Sphere s, Ray ray)
{
    const float epsilon = 1e-3;
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

	return (t = b - det) > epsilon ? t : ((t = b + det) > epsilon ? t : 0.0);
}

/*int intersect(Ray ray, out float t, out Sphere s, int avoid)*/
int intersect(Ray ray, out float t, out HitInfo hitInfo, int avoid)
{
	int id = -1;
	t = 1e5;
	hitInfo.obj = spheres[0];
	for(int i = 0; i < NUM_SPHERES; ++i)
    {
        if(i == avoid) continue;
		Sphere S = spheres[i];
		float d = intersect(S, ray);
		if(d != 0.0 && d < t)
        {
            t = d;
            id = i;

            hitInfo.obj = S;
            hitInfo.id  = i;
            hitInfo.dist = d;
        }
	}

	return id;
}

float intersect(Light light, Ray ray, out bool intersection)
{
    const float epsilon = 1e-3;
	vec3 op = light.pos - ray.origin;
    float b = dot(op, ray.direction);
    float det = b * b - dot(op, op) + light.radius * light.radius;

    intersection = true;
	if(det < 0.0)
    {
        intersection = false;
        return 0.0;
    }
    else
    {
        det = sqrt(det);
    }

	float t;
	return (t = b - det) > epsilon ? t :((t = b + det) > epsilon ? t : 0.0);
}

vec3 jitter(vec3 d, float phi, float sina, float cosa)
{
    /*return rHemisphereUniform(SEED);*/
	vec3 w = normalize(d);
    vec3 u = normalize(cross(w.yzx, w));
    vec3 v = cross(w, u);
	return (u * cos(phi) + v * sin(phi)) * sina + w * cosa;
}

// Schlick's approximation
// http://en.wikipedia.org/wiki/Schlick%27s_approximation
float fresnelSchlick(float R0, float HoV, out float R, out float T)
{
    const float fresnelBias  = 0.25;
    const float fresnelScale = 0.50;

    // Schlick reflection coefficient
    float RC = R0 + (1.0 - R0) * pow(1.0 - HoV, 5.0);

    float P = fresnelBias + fresnelScale * RC;

    // Reflection coefficient
    R = RC / P;

    // Transmission coefficient
    T = (1.0 - RC) / (1.0 - P);

    return P;
}

// http://http.developer.nvidia.com/CgTutorial/cg_tutorial_chapter07.html
float fresnelApprox(float NoL, out float R, out float T)
{
    const float fresnelBias  = 0.25;
    const float fresnelScale = 0.5;
    const float fresnelPower = 5.0;

    // Reflection coefficient
    R = clamp(fresnelBias + fresnelScale * pow(1.0 + NoL, fresnelPower), 0.0, 1.0);

    // Transmission coefficient
    T = 1.0 - R;

    return R;
}

float map(vec3 p, inout HitInfo hitInfo)
{
    float scene = NONE;

    int id = -1;

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

#if 0
    p -= vec3(0.0, 41.5, 0.0);

    float plane = sdPlaneY(p+vec3(0.0, 1.0, 0.0));
    opRep1(p.x, 4);
    opRep1(p.z, 3);
    float sphere = sdSphere(p+vec3(0.1, 0.2, 1.0), 0.5);
    float box = sdBox(p+vec3(1.2, 0.0, 0.0), vec3(0.5));
    float capsule = sdHexPrism(p-vec3(0.0, -0.3, 0.0), vec2(0.1, 0.2));

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



vec3 background(Ray ray, int depth, vec3 mask, vec3 direct, inout vec3 color)
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

#if 1
float trace(
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
#endif

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
        mat.type = DIFF;
        mat.color = 5.0 * vec3(0.9, 0.5, 0.4);
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

Ray BRDFNextRay(Ray ray, HitInfo hitInfo, inout vec3 color, inout vec3 mask, inout vec3 direct,
    inout vec3 C_O_L_O_R
)
{
    vec3 hit = hitInfo.pos;
    vec3 n   = hitInfo.normal;
    int id   = hitInfo.id;
    Sphere obj = hitInfo.obj;

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

            // Check if the current hit point if visible from the light
            #if RAYMARCHING
            HitInfo _;
            float t = trace(shadowRay, TMIN, TMAX, PRECISION, STEP_MAX, _);
            #else
            float t;
            HitInfo _;
            intersect(shadowRay, t, _, id);
            #endif

            // FIXME: not correct because refractive can block light completely
            bool intersection;
            float lightDist = intersect(light, shadowRay, intersection);
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

        C_O_L_O_R *= 2.0 * Albedo * max(0.0, dot(d, hitInfo.normal));
        #else
        vec3 d;
        if(BiasSampling)
        {
            // Biased sampling: cosine weighted
            // Lambertian BRDF = Albedo / PI
            // PDF = cos(angle) / PI
            d = getBiasedSample(hitInfo.normal, 1.0);

            // Modulate color with: BRDF * cos(angle) / PDF = Albedo
            C_O_L_O_R *= Albedo;
        }
        else
        {
            // Unbiased sampling: uniform over normal-oriented hemisphere
            // Lambertian BRDF = Albedo / PI
            // PDF = 1 / (2 * PI)
            d = getHemisphereSample(hitInfo.normal, 1.0);

            // Modulate color with: BRDF * cos(angle) / PDF = 2 * Albedo * cos(angle)
            C_O_L_O_R *= 2.0 * Albedo * max(0.0, dot(d, hitInfo.normal));
        }
        #endif


        // Direct
        if(DirectLight)
        {
            vec3 sunSampleDir = getConeSample(sunDirection, 1.0-sunAngularDiameterCos);
            float sunLight = dot(hitInfo.normal, sunSampleDir);

            if(sunLight > 0.0)
            {
                Ray shadowRay = Ray(hit, sunSampleDir);
                #if RAYMARCHING
                HitInfo hi;
                float t = trace(shadowRay, TMIN, TMAX, PRECISION, STEP_MAX, hi);
                int id = hi.id;
                if(id < 0)
                #else
                float t;
                HitInfo _;
		        if(intersect(shadowRay, t, _, id) < 0)
                #endif
                {
                    direct += C_O_L_O_R * sun(sunSampleDir) * sunLight * 1E-5;
                }

            }
        }

        float E = 1.0;//float(depth==0);

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
        /*C_O_L_O_R *= max(0.0, dot(ray.direction, hitInfo.normal));*/
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

            // cos(theta) = H.V
            float HoV = mix(cosTheta1, dot(refr, n), inside);

            // Fresnel: Schlick approximation
            P = fresnelSchlick(R0, HoV, R, T);
            #else
            // Fresnel: artist approximation
            P = fresnelApprox(NoL, R, T);
            #endif

            // Split ray: reflection + refraction
            if(rand() < P) // Reflection
            {
                mask *= R;
                C_O_L_O_R *= mat.color; //R;
                ray = Ray(hit, refl);
            }
            else // Refraction
            {
                mask *= mat.color * T;
                C_O_L_O_R *= mat.color * T;//max(0.0, dot(ray.direction, hitInfo.normal));
                ray = Ray(hit, refr);
            }
        }

        /*C_O_L_O_R *= mat.color;*/
    }

    return ray;
}

vec3 radiance(Ray ray)
{
	vec3 color  = vec3(0.0);
	vec3 direct = vec3(0.0);
	vec3 mask   = vec3(1.0);
	int id = -1;

	vec3 C_O_L_O_R  = vec3(1.0);

	for(int depth = 0; depth < MAXDEPTH; ++depth)
    {
        // If the mask is too low, the intensity gather
        // by the subsequent rays won't contribute much
        #if LOW_INTENSITY_OPTIMIZATION
        const vec3 MASK_THRESHOLD = vec3(INTENSITY_THRESHOLD);
        if(all(lessThan(mask, MASK_THRESHOLD))) break;
        #endif

        HitInfo hitInfo;

        #if RAYMARCHING
        float t = trace(ray, TMIN, TMAX, PRECISION, STEP_MAX, hitInfo);
        int id = hitInfo.id;
        if(id < 0) // No hit
        {
            return background(ray, depth, mask, direct, C_O_L_O_R);
        }
        #else
		float t;
        // If no hit, get sky color and exit
		if((id = intersect(ray, t, hitInfo, id)) < 0)
        {
            return background(ray, depth, mask, direct, C_O_L_O_R);
        }

		Sphere obj = hitInfo.obj;
		vec3 hit = ray.origin + t * ray.direction;
		vec3 n = normalize(hit - obj.pos);
        hitInfo.pos    = hit;
        hitInfo.normal = n;
        #endif

        // Compute lighting contribution and outgoing ray
        ray = BRDFNextRay(ray, hitInfo, color, mask, direct, C_O_L_O_R);
	}

    /*return C_O_L_O_R;*/
    return direct;
	return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    float time = uTime;
    time = 42.0;

	seed = time + uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

	vec2 uv = 2. * fragCoord.xy / uResolution.xy - 1.;

	vec3 camPos = vec3((2. *(uMouse.xy==vec2(0.)?.5*uResolution.xy:uMouse.xy) / uResolution.xy - 1.) * vec2(48., 40.) + vec2(50., 40.8), 169.);

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
