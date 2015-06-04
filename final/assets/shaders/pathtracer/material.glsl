#include "absorption_and_scattering.glsl"

// Material
struct Material
{
	float type;
    vec3  color; // TODO: rename to albedo
    float refractiveIndex; //TODO
    vec3  specular; //TODO remove
    float roughness;
    vec3  emissive;
    AbsorptionAndScattering as;
};

// Material type
#define NO_SHADING 0
#define DIFFUSE 1
#define SPECULAR 2
#define METALLIC 3
#define REFRACTIVE 4
