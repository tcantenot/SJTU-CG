#include "absorption_and_scattering.glsl"

// Material
struct Material
{
    vec3  albedo;
	float type;
    vec3  emissive;
    float roughness;
    AbsorptionAndScattering as;
    float refractiveIndex;
};

#define MATERIAL(type, albedo, refractiveIndex, roughness, emissive, as) \
    Material(albedo, type, emissive, roughness, as, refractiveIndex)


// Material type
#define NO_SHADING -1
#define DIFFUSE 1
#define METALLIC 2
#define REFRACTIVE 3
