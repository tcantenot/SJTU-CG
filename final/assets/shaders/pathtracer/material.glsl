// Material
struct Material
{
	float type;
    vec3  color;
    vec3  emissive;
    float roughness;
};

// Material type
#define NO_SHADING 0
#define DIFFUSE 1
#define SPECULAR 2
#define REFRACTIVE 3
