// Absorption and scattering properties
struct AbsorptionAndScattering
{
    vec3 absorption;
    float scattering;
};

// No absorption and scattering
const AbsorptionAndScattering NO_AS = AbsorptionAndScattering(vec3(0.0), 0.0);
