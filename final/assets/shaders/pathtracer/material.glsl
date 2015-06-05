#include "absorption_and_scattering.glsl"

// Material
// TODO: make test on structure alignment performance
struct Material
{
	float type;
    vec3  albedo;
    float refractiveIndex;
    float roughness;
    vec3  emissive;
    AbsorptionAndScattering as;
};

// Material type
#define NO_SHADING 0
#define DIFFUSE 1
#define METALLIC 2
#define REFRACTIVE 3
