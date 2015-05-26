////////////////////////////////////////////////////////////////////////////////
/// Fresnel reflectance: Schlick's approximation.
/// http://en.wikipedia.org/wiki/Schlick%27s_approximation
///
/// \param R0  Reflectange at normal incidence.
/// \param HoL Half-angle vector dot light vector (ray vector).
/// \param [out] R Reflection coefficient.
/// \param [out] T Transmission coefficient.
///
/// \return The probability of reflection (in [0, 1]).
////////////////////////////////////////////////////////////////////////////////
float fresnelSchlick(float R0, float HoL, out float R, out float T)
{
    const float bias  = 0.25;
    const float scale = 0.50;

    // Schlick reflection coefficient
    float RC = R0 + (1.0 - R0) * pow(1.0 - HoL, 5.0);

    float P = bias + scale * RC;

    // Reflection coefficient
    R = RC / P;

    // Transmission coefficient
    T = (1.0 - RC) / (1.0 - P);

    return P;
}

////////////////////////////////////////////////////////////////////////////////
/// Fresnel reflectance: approximation.
/// http://http.developer.nvidia.com/CgTutorial/cg_tutorial_chapter07.html
///
/// \param NoL   Normal to the surface dot light vector.
/// \param bias  Fresnel bias (artist control).
/// \param scale Fresnel scale (artist control).
/// \param power Fresnel power (artist control).
/// \param [out] R Reflection coefficient.
/// \param [out] T Transmission coefficient.
///
/// \return The probability of reflection (in [0, 1]).
////////////////////////////////////////////////////////////////////////////////
float fresnelApprox(
    float NoL,
    const float bias,
    const float scale,
    const float power,
    out float R,
    out float T
)
{
    // Reflection coefficient
    R = clamp(bias + scale * pow(1.0 + NoL, power), 0.0, 1.0);

    // Transmission coefficient
    T = 1.0 - R;

    return R;
}

float fresnelApprox(float NoL, out float R, out float T)
{
    const float BIAS  = 0.25;
    const float SCALE = 0.5;
    const float POWER = 5.0;

    return fresnelApprox(NoL, BIAS, SCALE, POWER, R, T);
}
