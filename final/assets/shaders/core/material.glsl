#include "absorption_and_scattering.glsl"

////////////////////////////////////////////////////////////////////////////////
/// Structure representing a generic material.
///
/// There are several families of materials:
///
///  - Diffuse only: type equals DIFFUSE, refractive index of 0.0,
///                  no absorption/scattering, color controlled by albedo,
///                  can be emissive as well.
///
///  - Diffuse reflective: type equal DIFFUSE, refractive index > 1.0,
///                        no absorption/scattering, color controlled by albedo,
///                        can be emissive as well.
///
///  - Metallic: type equals METALLIC, color controlled by albedo and
///              roughness/glossiness controlled by the roughness parameter.
///
///  - Refractive: type equals REFRACTIVE, refractive index > 1.0,
///                reflection/transmission controlled by Snell/Fresnel's
///                equations, color controlled by absorption, can scatter,
///                roughness/glossiness controlled by the roughness parameter.
///
///  - No shading: type equals NO_SHADING, color controlled by albedo,
///                is not shaded
///
////////////////////////////////////////////////////////////////////////////////
struct Material
{
    vec3  albedo;               // Albedo of the material
    float type;                 // Type of the material (see below)
    vec3  emissive;             // Emissive component
    float roughness;            // Roughness in [0, 1] (smooth - very rough)
    AbsorptionAndScattering as; // Absorption and scattering properties
    float refractiveIndex;      // Refractive index
};


// Macro used to create a material in a "more intuitive" way:
// the field have been reordered because the material structure follows some
// alignment rules to improve efficiency.
#define MATERIAL(type, albedo, refractiveIndex, roughness, emissive, as) \
    Material(albedo, type, emissive, roughness, as, refractiveIndex)


// Material type
#define NO_SHADING -1
#define DIFFUSE 1
#define METALLIC 2
#define REFRACTIVE 3
