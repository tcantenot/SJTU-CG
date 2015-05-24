#define SAMPLES 4
#define MAXDEPTH 5

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


#include "fragmentarium/sunsky.glsl"
#include "random.glsl"
#include "ray.glsl"
#include "distributions.glsl"

float seed = 0.0;
vec2 SEED = vec2(0.0);

float rand()
{
    SEED += vec2(1.0, -1.0);
    return hash2(SEED);
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

int lightCount = 1;


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

#define NUM_SPHERES 3
Sphere spheres[NUM_SPHERES] = Sphere[](
    // Red wall
	/*Sphere(1e5, vec3-1e5+1., 40.8, 81.6),	black,  red, DIFF),*/

    // Blue wall
	/*Sphere(1e5, vec3( 1e5+99., 40.8, 81.6), black, blue, DIFF),*/

    // Front wall
    /*Sphere(1e5, vec3(50., 40.8, -1e5), black, gray, DIFF),*/

    // Back wall
    /*Sphere(1e5, vec3(50., 40.8,  1e5+170), black, green, DIFF),*/

    // Floor
    /*Sphere(1e5, vec3(50., -1e5, 81.6), black, white, DIFF),*/
    Sphere(1e5, vec3(50., -1e5, 81.6), Material(DIFF, white, black)),

    // Ceiling
	/*Sphere(1e5, vec3(50.,  1e5+81.6, 81.6), black, gray, DIFF),*/

    // Metallic ball
	Sphere(16.5, vec3(27., 16.5, 47.), Material(SPEC, white, black)),

    // Glass ball
	Sphere(16.5, vec3(73., 16.5, 78.), Material(REFR, vec3(0.7, 1.0, 0.9), black))

    /*,*/

    // Ceiling light
    /*Sphere(600., vec3(50., 681.33, 81.6), 2.0*white, black, DIFF)*/
    /*Sphere(uLights[0].radius, uLights[0].pos, uLights[0].power*uLights[0].color, black, DIFF)*/

    // Other light
    /*,Sphere(uLights[1].radius, uLights[1].pos, 2.0*uLights[1].color, black, DIFF)*/
);

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

void background(Ray ray, int depth, inout vec3 color)
{
    bool directLight = true;

    if(!directLight)
    {
        color = color + sunsky(ray.direction);
    }
    else
    {
        color = color + (depth > 0 ? sky(ray.direction) : sunsky(ray.direction));
    }
}

#if 0
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

    // Raymarching using "sphere" tracing
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
#endif

Material getMaterial(int id)
{
    return spheres[id].material;
}

Ray BRDFNextRay(Ray ray, HitInfo hitInfo, inout vec3 color, inout vec3 mask)
{
    vec3 hit = hitInfo.pos;
    vec3 n   = hitInfo.normal;
    int id   = hitInfo.id;
    Sphere obj = hitInfo.obj;

    Material mat = getMaterial(id);

    // Diffuse material
    if(mat.type == DIFF)
    {
        // Make sure the normal of the surface points in the opposite direction
        // of the ray (in case we are inside the surface)
        vec3 normal = n * sign(-dot(n, ray.direction));

        // Check if current object is visible to any lights
        vec3 lightIntensity = vec3(0.0);
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
            #if 0
            HitInfo _;
            float t = trace(shadowRay, TMIN, TMAX, PRECISION, STEP_MAX, _);
            //t = abs(t);
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

        float E = 1.0;//float(depth==0);
        color += mask * mat.emissive * E + mask * mat.color * lightIntensity;
        mask *= mat.color;

        // New ray direction: random vector on the normal-oriented hemisphere
        float r2 = rand();
        vec3 d = jitter(normal, 2.0 * PI * rand(), sqrt(r2), sqrt(1.0 - r2));

        ray = Ray(hit, d);
    }
    // Specular (reflective) material
    else if(mat.type == SPEC)
    {
        color += mask * mat.emissive;
        mask *= mat.color;
        ray = Ray(hit, reflect(ray.direction, n));
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
                ray = Ray(hit, refl);
            }
            else // Refraction
            {
                mask *= mat.color * T;
                ray = Ray(hit, refr);
            }
        }
    }

    return ray;
}

vec3 radiance(Ray ray)
{
	vec3 color = vec3(0.0);
	vec3 mask  = vec3(1.0);
	int id = -1;

	for(int depth = 0; depth < MAXDEPTH; ++depth)
    {
        // If the mask is too low, the intensity gather
        // by the subsequent rays won't contribute much
        #if LOW_INTENSITY_OPTIMIZATION
        const vec3 MASK_THRESHOLD = vec3(INTENSITY_THRESHOLD);
        if(all(lessThan(mask, MASK_THRESHOLD))) break;
        #endif

		float t;
        HitInfo hitInfo;

        #if 0
        float t = trace(ray, TMIN, TMAX, PRECISION, STEP_MAX, hitInfo);
        int id = hitInfo.id;
        if(id < 0) // No hit
        {
            background(ray, depth, color);
            break;
        }
        #else
        // If no hit, get sky color and exit
		if((id = intersect(ray, t, hitInfo, id)) < 0)
        {
            background(ray, depth, color);
            break;
        }

		Sphere obj = hitInfo.obj;
		vec3 hit = ray.origin + t * ray.direction;
		vec3 n = normalize(hit - obj.pos);
        hitInfo.pos    = hit;
        hitInfo.normal = n;
        #endif

        // Compute lighting contribution and outgoing ray
        ray = BRDFNextRay(ray, hitInfo, color, mask);
	}

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

    float npaths = SAMPLES;
    float aa = float(npaths) / 2.0;
    for(int i = 0; i < npaths; i++)
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

	fragColor = vec4(pow(clamp(color, 0., 1.), vec3(1./2.2)), 1.);
}
