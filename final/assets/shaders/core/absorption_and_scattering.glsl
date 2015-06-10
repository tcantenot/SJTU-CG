// Absorption and scattering properties
struct AbsorptionAndScattering
{
    vec3 absorption;  // "Spectral" (RGB) absorption coefficient
    float scattering; // Scattering coefficient
};

// No absorption and scattering
const AbsorptionAndScattering NO_AS = AbsorptionAndScattering(vec3(0.0), 0.0);

////////////////////////////////////////////////////////////////////////////////
/// Compute how much light has been absorbed by the participating medium.
/// \param absorption "Spectral" absorption of the medium.
/// \param distance   Travelling distance of the ray in the medium.
/// \return The "spectral" transmitted fraction of light.
////////////////////////////////////////////////////////////////////////////////
vec3 computeTransmission(vec3 absorption, float d)
{
    // Scattering equation
    return exp(-(absorption * d));
}
