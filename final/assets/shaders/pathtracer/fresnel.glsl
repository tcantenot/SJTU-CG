////////////////////////////////////////////////////////////////////////////////
/// Fresnel equations.
/// http://en.wikipedia.org/wiki/Fresnel_equations
///
/// \param n1 Index of refraction of incidence medium.
/// \param n2 Index of refraction of transmitted medium.
/// \param cosI Cosine of incidence angle.
/// \param cosT Cosine of transmittance angle.
/// \param [out] R Reflection coefficient.
/// \param [out] T Transmission coefficient.
///
/// \return The reflection coefficient.
////////////////////////////////////////////////////////////////////////////////
float computeFresnel(float n1, float n2, float cosI, float cosT,
    out float R, out float T
)
{
    float n1cosI = n1 * cosI;
    float n1cosT = n1 * cosT;
    float n2cosI = n2 * cosI;
    float n2cosT = n2 * cosT;

    // Reflectance for s-polarized light
    float Rs = pow((n1cosI - n2cosT) / (n1cosI + n2cosT), 2.0);

    // Reflectance for p-polarized light
    float Rp = pow((n1cosT - n2cosI) / (n1cosT + n2cosI), 2.0);

    // Reflectance for unpolarised light
    R = (Rs + Rp) / 2.0;

    // Transmittance for unpolarised light
    T = 1.0 - R;

    return R;
}

////////////////////////////////////////////////////////////////////////////////
/// Fresnel equations.
/// http://en.wikipedia.org/wiki/Fresnel_equations
///
/// \param n1 Index of refraction of incidence medium.
/// \param n2 Index of refraction of transmitted medium.
/// \param cosI Cosine of incidence angle.
/// \param cosT Cosine of transmittance angle.
///
/// \return The reflection coefficient.
////////////////////////////////////////////////////////////////////////////////
float computeFresnel(float n1, float n2, float cosI, float cosT)
{
    float R, T;
    return computeFresnel(n1, n2, cosI, cosT, R, T);
}

////////////////////////////////////////////////////////////////////////////////
/// Fresnel reflectance: Schlick's approximation.
/// http://en.wikipedia.org/wiki/Schlick%27s_approximation
///
/// \param R0  Reflectance at normal incidence.
/// \param HoL Half-angle vector dot light vector (ray vector).
/// \param [out] R Reflection coefficient.
/// \param [out] T Transmission coefficient.
///
/// \return The probability of reflection (in [0, 1]).
////////////////////////////////////////////////////////////////////////////////
float fresnelSchlick(float R0, float HoL, out float R, out float T)
{
    // Schlick reflection coefficient
    R = R0 + (1.0 - R0) * pow(1.0 - HoL, 5.0);

    // Transmission coefficient
    T = 1.0 - R;

    return R;
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
    const float BIAS  = 0.0;
    const float SCALE = 1.0;
    const float POWER = 5.0;

    return fresnelApprox(NoL, BIAS, SCALE, POWER, R, T);
}
