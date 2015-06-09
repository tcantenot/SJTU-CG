/// FOG EFFECTS ///

// See: http://www.iquilezles.org/www/articles/fog/fog.htm

const vec3 DEFAULT_FOG_COLOR = vec3(0.5, 0.6, 0.7);

////////////////////////////////////////////////////////////////////////////////
/// \brief Apply fog with constant density.
/// \param color    Original color of the pixel.
/// \param fogColor Fog color.
/// \param d        Camera to point distance.
/// \param b        Density coefficient.
/// \return The new color.
////////////////////////////////////////////////////////////////////////////////
vec3 applyFog(vec3 color, vec3 fogColor, float d, float b)
{
    float fogAmount = 1.0 - exp(-d * b);
    return mix(color, fogColor, fogAmount);
}

vec3 applyFog(vec3 color, float d, float b)
{
    return applyFog(color, DEFAULT_FOG_COLOR, d, b);
}

////////////////////////////////////////////////////////////////////////////////
/// \brief Apply fog with constant density.
/// \param color    Original color of the pixel.
/// \param fogColor Fog color.
/// \param d        Camera to point distance.
/// \param be       Extinction coefficient.
/// \param bi       Inscatter coefficient.
/// \return The new color.
////////////////////////////////////////////////////////////////////////////////
vec3 applyFog(vec3 color, vec3 fogColor, float d, float be, float bi)
{
    float extinction = exp(-d * be);
    float inscatter  = exp(-d * bi);
    return color * (1.0 - extinction) + fogColor * inscatter;
}

vec3 applyFog(vec3 color, float d, float be, float bi)
{
    return applyFog(color, DEFAULT_FOG_COLOR, d, be, bi);
}


////////////////////////////////////////////////////////////////////////////////
/// \brief Apply fog with constant density.
/// \param color    Original color of the pixel.
/// \param fogColor Fog color.
/// \param d        Camera to point distance.
/// \param be       Spectral extinction coefficient.
/// \param bi       Spectral inscatter coefficient.
/// \return The new color.
////////////////////////////////////////////////////////////////////////////////
vec3 applyFog(vec3 color, vec3 fogColor, float d, vec3 be, vec3 bi)
{
    vec3 extinction = vec3(exp(-d * be.r), exp(-d * be.g), exp(-d * be.b));
    vec3 inscatter  = vec3(exp(-d * bi.r), exp(-d * bi.g), exp(-d * bi.b));
    return color * (1.0 - extinction) + fogColor * inscatter;
}

vec3 applyFog(vec3 color, float d, vec3 be, vec3 bi)
{
    return applyFog(color, DEFAULT_FOG_COLOR, d, be, bi);
}


////////////////////////////////////////////////////////////////////////////////
/// \brief Apply fog with constant density.
/// \param color    Original color of the pixel.
/// \param fogColor Fog color.
/// \param d        Camera to point distance.
/// \param rd       Camera to point vector.
/// \param sunDir   Sun light direction.
/// \param b        Density coefficient.
/// \return The new color.
////////////////////////////////////////////////////////////////////////////////
vec3 applyFog(vec3 color, float d, vec3 rd, vec3 sunDir, float b)
{
    float fogAmount = 1.0 - exp(-d * b);
    float sunAmount = max(dot(rd, sunDir), 0.0);
    vec3  fogColor  = mix(
        vec3(0.5, 0.6, 0.7), // Blueish
        vec3(1.0, 0.9, 0.7), // Yellowish
        pow(sunAmount, 8.0)
    );
    return mix(color, fogColor, fogAmount);
}

////////////////////////////////////////////////////////////////////////////////
/// \brief Apply fog with non constant density (based on altitude).
/// \param color    Original color of the pixel.
/// \param fogColor Fog color.
/// \param d        Camera to point distance.
/// \param ro       Camera position.
/// \param rd       Camera to point vector.
/// \param b        Density coefficient.
/// \return The new color.
////////////////////////////////////////////////////////////////////////////////
vec3 applyNonConstFog(vec3 color, vec3 fogColor, float d, vec3 ro, vec3 rd, float b)
{
    const float c = 1.0;
    float fogAmount = c * exp(-ro.y * b) * (1.0 - exp(-d * rd.y * b)) / rd.y;
    return mix(color, fogColor, fogAmount);
}

vec3 applyNonConstFog(vec3 color, float d, vec3 ro, vec3 rd, float b)
{
    return applyNonConstFog(color, DEFAULT_FOG_COLOR, d, ro, rd, b);
}

////////////////////////////////////////////////////////////////////////////////
/// \brief Apply fog with non constant density (based on altitude).
/// \param color    Original color of the pixel.
/// \param fogColor Fog color.
/// \param d        Camera to point distance.
/// \param ro       Camera position.
/// \param rd       Camera to point vector.
/// \param b        Spectral density coefficient.
/// \return The new color.
////////////////////////////////////////////////////////////////////////////////
vec3 applyNonConstFog(vec3 color, vec3 fogColor, float d, vec3 ro, vec3 rd, vec3 b)
{
    const float c = 1.0;
    vec3 fogAmount = vec3(0.0);
    fogAmount.r = c * exp(-ro.y * b.r) * (1.0 - exp(-d * rd.y * b.r)) / rd.y;
    fogAmount.g = c * exp(-ro.y * b.g) * (1.0 - exp(-d * rd.y * b.g)) / rd.y;
    fogAmount.b = c * exp(-ro.y * b.b) * (1.0 - exp(-d * rd.y * b.b)) / rd.y;
    return mix(color, fogColor, fogAmount);
}

vec3 applyNonConstFog(vec3 color, float d, vec3 ro, vec3 rd, vec3 b)
{
    return applyNonConstFog(color, DEFAULT_FOG_COLOR, d, ro, rd, b);
}
