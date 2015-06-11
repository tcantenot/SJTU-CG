#include "core.glsl"
#include "fresnel.glsl"
#include "sampling.glsl"

#ifndef PI
#define PI 3.14159265359
#endif

// Max ray depth
#ifndef MAX_DEPTH
#define MAX_DEPTH 8
#endif

// Enable/disable importance sampling
#ifndef IMPORTANCE_SAMPLING
#define IMPORTANCE_SAMPLING 1
#endif

// Enable/disable Russian Roulette ray termination
#ifndef RUSSIAN_ROULETTE
#define RUSSIAN_ROULETTE 1
#endif

// Min depth for Russian Roulette
#ifndef RUSSIAN_ROULETTE_DEPTH
#define RUSSIAN_ROULETTE_DEPTH 5
#endif

// Enable/Disable the direct lighting (sun and lights)
#ifndef DIRECT_LIGHTING
#define DIRECT_LIGHTING 1
#endif

// Enable/Disable the sun and sky lighting
#ifndef SUN_SKY_BACKGROUND
#define SUN_SKY_BACKGROUND 0
#endif

// Enable/Disable the sun direct lighting
#ifndef SUN
#define SUN 0
#elif SUN
#include "../env/sunsky.glsl"
#endif

// Lights
#ifndef LIGHTS
#if HookLightCount > 0
#define LIGHTS 1
#else
#define LIGHTS 0
#endif

// Use the real Fresnel equations
#ifndef REAL_FRESNEL_EQUATIONS
#define REAL_FRESNEL_EQUATIONS 1
#endif

// Use Schlick's approximation for Fresnel effect if real Fresnel not used
#ifndef FRESNEL_SCHLICK
#define FRESNEL_SCHLICK 1
#endif

// Enable glossy reflection
#ifndef GLOSSY_REFLECTION
#define GLOSSY_REFLECTION 1
#endif

// Enable/Disable absorption and scattering
#ifndef ABSORPTION_AND_SCATTERING
#define ABSORPTION_AND_SCATTERING 1
#endif

// Enable/disable Russian Roulette for subsurface scattering ray termination
#ifndef RUSSIAN_ROULETTE_SSS
#define RUSSIAN_ROULETTE_SSS 1
#endif

// Min depth for Russian Roulette of subsurface scattering
#ifndef RUSSIAN_ROULETTE_SSS_DEPTH
#define RUSSIAN_ROULETTE_SSS_DEPTH 5
#endif

// Stop ray once the reflectance has gone too low
// (the ray will probably not carry much energy)
#ifndef LOW_REFLECTANCE_BIASED_OPTIMIZATION
#define LOW_REFLECTANCE_BIASED_OPTIMIZATION 0
#endif

// Minimum reflectance used for ray termination
#ifndef MIN_REFLECTANCE
#define MIN_REFLECTANCE 0.05
#endif

// Bias to add on ray bounce to avoid self-intersection
#ifndef BOUNCE_BIAS
#define BOUNCE_BIAS 0.000
#endif

// Swap-if function
#define SWAP_IF(type, l, r, b) {type t = l; l = mix(l, r, b); r = mix(r, t, b);}


////////////////////////////////////////////////////////////////////////////////
/// Radiance:
///
/// L0  = Le0 + f0*L1
/// L1  = Le1 + f1*L2
/// ...
/// LN  = Le(N-1) + fN*L(N-1)
///
///
/// L0 = Le0 + f0*(Le1 + f1*L2)
///    = Le0 + f0*(Le1 + f1*(Le2 + f2*L3)
///    = ...
///    = Le0 + f0*Le1 + f0*f1*Le2 + f0*f1*f2*Le3 + ...
///
///
/// Pseudo-code:
///
///     L = 0 // Accumulated light (color)
///     F = 1 // Accumulated reflectance
///
///     for(int depth = 0; depth < MAX_DEPTH; ++depth)
///     {
///          L += F * Lei
///          F *= fi
///     }
///
///     return L
///
////////////////////////////////////////////////////////////////////////////////
vec3 radiance(Ray ray)
{
    HitInfo hitInfo;
    hitInfo.id = -1;

    int depth = 0;

    vec3 L = vec3(0.0); // Accumulated color
    vec3 F = vec3(1.0); // Accumulated reflectance

    #if ABSORPTION_AND_SCATTERING
    // Assumption: ray starts in non absorbing/scattering media
    const AbsorptionAndScattering DEFAULT_AS = NO_AS;
    AbsorptionAndScattering currentAS = DEFAULT_AS;
    #endif

    for(int depth = 0; depth < MAX_DEPTH; ++depth)
    {
        #if LOW_REFLECTANCE_BIASED_OPTIMIZATION
        {
            float f = max(F.x, max(F.y, F.z));
            if(f < MIN_REFLECTANCE)
            {
                return L;
            }
        }
        #endif

        // Find intersection with the scene
        bool intersection = HookLightRay(ray, hitInfo.id, hitInfo);

        vec3 hit = hitInfo.pos;
        vec3 n   = hitInfo.normal;

        Material mat = HookMaterial(hitInfo);

        // Absorption and scattering
        #if ABSORPTION_AND_SCATTERING
        const vec3 ZERO_ABSORPTION_EPS = vec3(0.0001);
        if((currentAS.scattering > 0.0 ||
           any(greaterThan(currentAS.absorption, ZERO_ABSORPTION_EPS)))
        )
        {
            // Assume a random transmission and compute the corresponding
            // scattering distance with the scattering formula:
            // tr = exp(-scattering * distance)
            float tr = max(rand(), 0.00001);
            float scatteringDistance = -log(tr) / currentAS.scattering;

            // Absorption and scattering
            if(scatteringDistance < hitInfo.dist)
            {
                // Compute how much light has been absorbed by the current medium
                // before if was scattered
                F *= computeTransmission(currentAS.absorption, scatteringDistance);

                // Determine the direction of the scattered ray
                // -> assume isotropic scattering
                Ray nextRay;
                nextRay.origin = ray.origin + scatteringDistance * ray.direction;
                nextRay.direction = randomSphereVector();
                /*nextRay.direction = randomConeVector(ray.direction, 0.98);*/
                ray = nextRay;

                // Russian Roulette
                // See: http://www.cs.rutgers.edu/~decarlo/readings/mcrt-sg03c.pdf p116
                #if RUSSIAN_ROULETTE_SSS
                if(depth > RUSSIAN_ROULETTE_SSS_DEPTH)
                {
                    float p = max(F.x, max(F.y, F.z));
                    if(rand() < p)
                    {
                        F /= p; // Divide by p to keep an unbiased estimator
                    }
                    else
                    {
                        return L;
                    }
                }
                #endif

                // Go to next ray
                continue;
            }
            // Absorption only
            else
            {
                // Compute how much light has been absorbed by the current medium
                F *= computeTransmission(currentAS.absorption, hitInfo.dist);
            }
        }
        #endif //ABSORPTION_AND_SCATTERING

        // If no hit, get background color and exit
        if(!intersection)
        {
            return L + F * HookBackground(ray, depth);
        }


        // Special case to handle non shaded entities (spherical lights, ...)
        if(mat.type == NO_SHADING)
        {
            return L + F * mat.albedo;
        }

        // Metallic materials
        if(mat.type == METALLIC)
        {
            F *= mat.albedo;

            // Direction of reflection for a perfect mirror
            vec3 refl = reflect(ray.direction, n);

            // Glossiness
            float alpha = 1.0 - mat.roughness * mat.roughness;

            // If the roughness is 0 the material is a perfect mirror and
            // the output cone will be reduce to a single direction:
            // the reflection one
            refl = randomConeVector(refl, alpha);

            // Next ray
            ray = Ray(hit + n * BOUNCE_BIAS, refl);

            continue;
        }

        const float AIR_IOR = 1.000293;
        float n1 = AIR_IOR;
        float n2 = mat.refractiveIndex;

        // n is the normal vector that points from the surface towards its outside.
        // NoL is positive if the ray is coming from the inside of the surface
        // (negative side) and negative if it is coming from the outside.
        float NoL = dot(n, ray.direction);

        // Cosine of the angle of incidence: must be positive for the Snell's law
        float cosI = abs(NoL);

        // Relative position from the refractive material:
        // 0: outside, 1: inside
        float inside = float(NoL > 0.0);

        // If we are inside the material swap the medium
        SWAP_IF(float, n1, n2, inside)

        // Ratio of refractive indices
        float r = n1 / n2;

        // Snell's law: square of cosine of the angle of refraction
        // http://en.wikipedia.org/wiki/Snell%27s_law#Derivations_and_formula
        float cosT = 1.0 - r * r * (1.0 - cosI * cosI);

        // Total internal reflection
        // http://en.wikipedia.org/wiki/Total_internal_reflection
        if(cosT < 0.0)
        {
            // Direction of reflection for a perfect mirror
            vec3 refl = reflect(ray.direction, n);

            // Glossiness
            float alpha = 1.0 - mat.roughness * mat.roughness;

            // If the roughness is 0 the material is a perfect mirror and
            // the output cone will be reduce to a single direction:
            // the reflection one
            refl = randomConeVector(refl, alpha);

            // Next ray
            ray = Ray(hit + n * BOUNCE_BIAS, refl);

            continue;
        }


        // /!\ The light path is inverted in path tracing.
        // For this reason, we arrive either from the reflection or
        // refraction side, and not the incident one.
        // This is not an issue because the propagation is reversible.


        // Direction of reflection for a perfect mirror which is also the
        // direction of incidence of light: surface -> light source
        vec3 refl = reflect(ray.direction, n);

        // Refraction direction
        // http://en.wikipedia.org/wiki/Snell%27s_law#Derivations_and_formula
        vec3 refr = r * refl + (r * cosI + sqrt(cosT)) * n * sign(NoL);
        refr = normalize(refr);


        // Reflection and transmission coefficients
        // and reflection probability
        float R, T, P;

        #if REAL_FRESNEL_EQUATIONS
        P = computeFresnel(n1, n2, cosI, cosT, R, T);
        #elif FRESNEL_SCHLICK
        // Reflection coefficient at normal incidence
        float R0 = pow((n1 - n2) / (n1 + n2), 2.0);

        // cos(theta) = H.L
        float HoL = mix(cosI, dot(refr, n), inside);

        // Fresnel: Schlick approximation
        P = fresnelSchlick(R0, HoL, R, T);
        #else
        // Fresnel: artist approximation
        P = fresnelApprox(NoL, R, T);
        #endif


        // Reflection according to refractive index and Fresnel coefficient
        bool reflectFromSurface = mat.refractiveIndex > 1.0 && rand() < P;

        // Split ray: reflection + refraction
        if(reflectFromSurface) // Reflection
        {
            // Modulate reflectance by the reflection coefficient
            // and divide by P to remain unbiased (RR)
            F *= R / P;

            #if GLOSSY_REFLECTION
            // Glossiness
            float alpha = 1.0 - mat.roughness * mat.roughness;

            // If the roughness is 0 the material is a perfect
            // refractive material and the output cone will be reduce to
            // a single direction: the refraction one
            refl = randomConeVector(refl, alpha);
            #endif

            // Next ray
            ray = Ray(hit + n * BOUNCE_BIAS, refl);
        }
        else if(mat.type == REFRACTIVE) // Refraction
        {
            // Modulate reflectance by the transmission coefficient
            // and divide by (1 - P) to remain unbiased (RR)
            F *= T / (1.0 - P);

            #if ABSORPTION_AND_SCATTERING
            AbsorptionAndScattering ias = DEFAULT_AS;
            AbsorptionAndScattering tas = mat.as;

            SWAP_IF(vec3,  ias.absorption, tas.absorption, inside)
            SWAP_IF(float, ias.scattering, tas.scattering, inside)

            // The ray entered a new medium
            currentAS = tas;
            #endif

            // Ignore self-intersection
            hitInfo.id = -1;

            // Next ray
            ray = Ray(hit - n * BOUNCE_BIAS, refr);
        }
        else // Diffuse or emissive
        {
            L += F * mat.emissive;

            vec3 f = mat.albedo;

            // Russian Roulette
            // See: http://www.cs.rutgers.edu/~decarlo/readings/mcrt-sg03c.pdf p116
            #if RUSSIAN_ROULETTE
            if(depth > RUSSIAN_ROULETTE_DEPTH)
            {
                // Hemispherical reflectance of material p = 1 - alpha
                // where alpha is the absorption probability
                float p = max(f.x, max(f.y, f.z));
                if(rand() < p)
                {
                    f /= p; // Divide by p to keep an unbiased estimator
                }
                else
                {
                    return L;
                }
            }
            #endif

            Ray nextRay;
            nextRay.origin = hitInfo.pos + n * BOUNCE_BIAS;

            #if IMPORTANCE_SAMPLING
            // http://people.cs.kuleuven.be/~philip.dutre/GI/TotalCompendium.pdf (35)

            // Biased sampling: cosine weighted
            // Lambertian BRDF = Albedo / PI
            // PDF = cos(angle) / PI
            nextRay.direction = randomCosineWeightedVector(n);

            // Modulate reflectance with: BRDF * cos(angle) / PDF = Albedo
            F *= f;
            #else
            // http://people.cs.kuleuven.be/~philip.dutre/GI/TotalCompendium.pdf (34)

            // Unbiased sampling: uniform over normal-oriented hemisphere
            // Lambertian BRDF = Albedo / PI
            // PDF = 1 / (2 * PI)
            nextRay.direction = randomHemisphereVector(n);

            // Modulate reflectance with: BRDF * cos(angle) / PDF = 2 * Albedo * cos(angle)
            F *= 2.0 * f * max(0.0, dot(nextRay.direction, n));
            #endif


            // Direct lighting
            #if DIRECT_LIGHTING
            {
                // Direct sun light
                #if SUN
                {
                    // Take a random direction towards the sun
                    vec3 sunSampleDir = randomConeVector(getSunDirection(), getSunCosAngularDiameter());
                    float sunLight = dot(n, sunSampleDir);

                    if(sunLight > 0.0)
                    {
                        Ray shadowRay = Ray(hit + n * BOUNCE_BIAS, sunSampleDir);
                        HitInfo _;
                        if(!HookShadowRay(shadowRay, hitInfo.id, _))
                        {
                            L += F * sun(sunSampleDir) * sunLight * 1E-5;
                        }
                    }
                }
                #endif

                // Take a sample for each light
                #if LIGHTS
                vec3 lightIntensity = vec3(0.0);
                for(int i = 0; i < HookLightCount; ++i)
                {
                    Light light = HookLights(i);

                    // Vector hit-light
                    vec3 lightDir = light.pos - hit;
                    float r2 = light.radius * light.radius;

                    // Maximum angle to reach the spherical light (defines a cone)
                    float sinThetaMax = clamp(r2 / dot(lightDir, lightDir), 0.0, 1.0);
                    float cosThetaMax = sqrt(1.0 - sinThetaMax);

                    // Light direction: random vector in the cone of light
                    vec3 l = randomConeVector(lightDir, cosThetaMax);


                    // Shadow ray
                    Ray shadowRay = Ray(hit + n * BOUNCE_BIAS, l);

                    // Check if the current hit point is potentially shadowed
                    HitInfo shadowingInfo;
                    bool ps = HookShadowRay(shadowRay, hitInfo.id, shadowingInfo);
                    float lightDist = distanceTo(shadowRay, light);
                    if(lightDist < shadowingInfo.dist)
                    {
                        vec3 I = light.power * light.color * clamp(dot(l, n), 0.0, 1.0);

                        // Inverse PDF for random ray direction in unit oriented hemisphere
                        // proportional to solid angle in [0, thetaMax]
                        // (cone of angle thetaMax aligned with the light vector)
                        // http://people.cs.kuleuven.be/~philip.dutre/GI/TotalCompendium.pdf (34)
                        float invpdf = 2.0 * PI * (1.0 - cosThetaMax);

                        lightIntensity += (I * invpdf) / PI;
                    }
                }

                L += F * lightIntensity;
                #endif
            }
            #endif

            ray = nextRay;
        }
    }

    return L;
}
