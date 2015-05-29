#include "fresnel.glsl"
#include "hitinfo.glsl"
#include "light.glsl"
#include "material.glsl"
#include "random.glsl"
#include "ray.glsl"
#include "sampling.glsl"
#include "sunsky.glsl"

#ifndef PI
#define PI 3.14159265359
#endif

// Max ray depth
#ifndef MAX_DEPTH
#define MAX_DEPTH 8
#endif

// Enable the sun and sky lighting
#ifndef SUN_SKY
#define SUN_SKY 1
#endif

// Use Schlick's approximation for Fresnel effect
#ifndef FRESNEL_SCHLICK
#define FRESNEL_SCHLICK 1
#endif

// Enable glossy refraction
#ifndef GLOSSY_REFRACTION
#define GLOSSY_REFRACTION 1
#endif


bool BRDFNextRay(
    Ray ray,
    HitInfo hitInfo,
    float depth,
    inout vec3 color,
    inout vec3 direct,
    out Ray nextRay
)
{
    vec3 hit = hitInfo.pos;
    vec3 n   = hitInfo.normal;

    Material mat = getMaterial(hitInfo);

    color *= mat.color;

    // Diffuse material
    if(mat.type == DIFFUSE)
    {
        // Make sure the normal of the surface points in the opposite direction
        // of the ray (in case we are inside the surface)
        vec3 normal = n * sign(-dot(n, ray.direction));

        // Choose a random sampling direction and update the accumulated color
        vec3 d = randomSampling(normal, color);

        // Direct lighting
        {
            // Direct sun light
            #if SUN_SKY
            {
                vec3 sunSampleDir = coneSample(sunDirection, sunAngularDiameterCos);
                float sunLight = dot(normal, sunSampleDir);

                if(sunLight > 0.0)
                {
                    Ray shadowRay = Ray(hit, sunSampleDir);
                    HitInfo _;
                    if(!shadowtrace(shadowRay, hitInfo.id, _))
                    {
                        direct += color * sun(sunSampleDir) * sunLight * 1E-5;
                    }
                }
            }
            #endif

            // Check if current object is visible to any lights
            #if LIGHTS
            vec3 lightIntensity = vec3(0.0);
            for(int i = 0; i < LIGHT_COUNT; ++i)
            {
                Light light = uLights[i];

                // Vector hit-light
                vec3 lightDir = light.pos - hit;
                float r2 = light.radius * light.radius;

                // Cosine of the maximum angle to reach the light (cone of light rays)
                float cosThetaMax = sqrt(1.0 - clamp(r2 / dot(lightDir, lightDir), 0.0, 1.0));

                // Light direction: random vector in the cone of light
                vec3 l = coneSample(lightDir, cosThetaMax);

                // Shadow ray
                Ray shadowRay = Ray(hit, l);

                HitInfo shadowingInfo;

                // Check if the current hit point is potentially shadowed
                // FIXME: not correct because refractive can block light completely
                bool ps = shadowtrace(shadowRay, hitInfo.id, shadowingInfo);

                float lightDist = distance(shadowRay, light);
                // FIXME: intersection should always be true (the shadowRay is aimed towards the light)
                if(lightDist < shadowingInfo.dist)
                {
                    vec3 I = light.power * light.color * clamp(dot(l, n), 0.0, 1.0);
                    float omega = 2.0 * PI * (1.0 - cosThetaMax);
                    lightIntensity += (I * omega) / PI;
                }
            }
            direct += color * lightIntensity;
            #endif
        }

        /*float E = float(depth == 0);*/
        float E = 1.0;

        direct += color * mat.emissive * E;

        nextRay = Ray(hit, d);
    }
    // Specular (reflective) material
    else if(mat.type == SPECULAR)
    {
        vec3 refl = reflect(ray.direction, n);
        float alpha = 1.0 - mat.roughness * mat.roughness;
        vec3 dir = coneSample(refl, alpha);

        nextRay = Ray(hit, dir);
    }
    // Refractive material
    else if(mat.type == REFRACTIVE)
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
                color *= R;

                #if GLOSSY_REFRACTION
                float alpha = 1.0 - mat.roughness * mat.roughness;
                refl = coneSample(refl, alpha);
                #endif

                nextRay = Ray(hit, refl);
            }
            else // Refraction
            {
                color *= T;
                nextRay = Ray(hit, refr);
            }
        }
        else // Total internal reflection
        {
            vec3 refl = reflect(ray.direction, n);

            #if GLOSSY_REFRACTION
            float alpha = 1.0 - mat.roughness * mat.roughness;
            refl = coneSample(refl, alpha);
            #endif

            nextRay = Ray(hit, refl);
        }
    }
    else if(mat.type == NO_SHADING)
    {
        direct = mat.color;
        return false;
    }

    return true;
}

vec3 radiance(Ray ray)
{
	vec3 direct = vec3(0.0);

    HitInfo hitInfo;
	hitInfo.id = -1;

	vec3 color  = vec3(1.0);

	for(int depth = 0; depth < MAX_DEPTH; ++depth)
    {
        // If no hit, get background color and exit
        if(!trace(ray, hitInfo.id, hitInfo))
        {
            return direct + color * background(ray, depth);
        }

        // Compute lighting contribution and outgoing ray
        if(!BRDFNextRay(ray, hitInfo, depth, color, direct, ray))
        {
            break;
        }
	}

    return direct;
}


