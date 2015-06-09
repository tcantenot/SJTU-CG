#include "random.glsl"

#ifndef PI
#define PI 3.14159265359
#endif

#ifndef TWO_PI
#define TWO_PI 6.283185307
#endif


// Enable/Disable stratified sampling
#ifndef STRATIFIED_SAMPLING
#define STRATIFIED_SAMPLING 1
#endif

// Enable/Disable hybrid stratified sampling (stratified sampling must be enabled)
// Start with stratified sampling for a number of frame and then falls back to
// uniform sampling
#ifndef HYBRID_STRATIFIED_SAMPLING
#define HYBRID_STRATIFIED_SAMPLING 0
#endif

// Maximum frame number for the hybrid stratified sampling
#ifndef HYBRID_STRATIFIED_SAMPLING_MAX_FRAME
#define HYBRID_STRATIFIED_SAMPLING_MAX_FRAME 50
#endif


#if STRATIFIED_SAMPLING
// Stratified sampling frame number
float gStratFrame = uIterations;

// Stratified sampling offset
vec2 gStratOffset = vec2(
    floor(mod(float(gStratFrame) * 1.0, 10.0)),
    floor(mod(float(gStratFrame) * 0.1, 10.0))
) / 10.0;
#endif


////////////////////////////////////////////////////////////////////////////////
/// Construct a vector orthogonal to the given one.
/// http://lolengine.net/blog/2013/09/21/picking-orthogonal-vector-combing-coconuts
/// \param v Vector (non normalized).
/// \return A orthogonal vector to v (non normalized).
////////////////////////////////////////////////////////////////////////////////
vec3 orthogonal(vec3 v)
{
	return abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0) : vec3(0.0, -v.z, v.y);
}


////////////////////////////////////////////////////////////////////////////////
/// Generate random direction on unit hemisphere proportional to
/// cosine-weighted solid angle.
/// PDF = cos(angle) / pi.
///
/// \param dir Orientation of the sampled hemisphere.
///
/// \return The randomly generated unit vector.
////////////////////////////////////////////////////////////////////////////////
vec3 randomCosineWeightedVector(vec3 dir)
{
	vec2 r = rand2();

    #if STRATIFIED_SAMPLING
    #if HYBRID_STRATIFIED_SAMPLING
    if(gStratFrame < HYBRID_STRATIFIED_SAMPLING_MAX_FRAME)
    #endif
    {
        r *= 0.1;
        r += gStratOffset;
        gStratOffset = mod(gStratOffset + vec2(0.1, 0.9), 1.0);
    }
    #endif

    float phi = TWO_PI * r.x;
    float cosTheta = sqrt(r.y);
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	// Create an orthogonal basis
	vec3 w = normalize(dir);
	vec3 u = normalize(orthogonal(w));
	vec3 v = normalize(cross(w, u));

	return (cos(phi) * u + sin(phi) * v) * sinTheta + cosTheta * w;
}


////////////////////////////////////////////////////////////////////////////////
/// Generate random direction on unit oriented hemisphere proportional to solid
/// angle in [0, thetaMax].
/// PDF = 1 / (2pi * (1 - cos(thetaMax)),
///
/// \param dir         Orientation of the sampled hemisphere.
/// \param cosThetaMax Cosine of the maximum angle to the sample vector.
///
/// \return The randomly generated unit vector.
////////////////////////////////////////////////////////////////////////////////
vec3 randomConeVector(vec3 dir, float cosThetaMax)
{
	vec2 r = rand2();

    #if STRATIFIED_SAMPLING
    #if HYBRID_STRATIFIED_SAMPLING
    if(gStratFrame < HYBRID_STRATIFIED_SAMPLING_MAX_FRAME)
    #endif
    {
        r *= 0.1;
        r += gStratOffset;
    }
    #endif

    float phi = TWO_PI * r.x;
    float cosTheta = 1.0 - r.y * (1.0 - cosThetaMax);
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	// Create an orthogonal basis
	vec3 w = normalize(dir);
	vec3 u = normalize(orthogonal(w));
	vec3 v = normalize(cross(w, u));

	return (cos(phi) * u + sin(phi) * v) * sinTheta + cosTheta * w;
}

////////////////////////////////////////////////////////////////////////////////
/// Generate uniform random direction on unit hemisphere.
/// PDF = 1 / 2pi.
///
/// \param dir Orientation of the sampled hemisphere.
///
/// \return The randomly generated unit vector.
////////////////////////////////////////////////////////////////////////////////
vec3 randomHemisphereVector(vec3 dir)
{
    vec2 r = rand2();

    #if STRATIFIED_SAMPLING
    #if HYBRID_STRATIFIED_SAMPLING
    if(gStratFrame < HYBRID_STRATIFIED_SAMPLING_MAX_FRAME)
    #endif
    {
        r *= 0.1;
        r += gStratOffset;
        gStratOffset = mod(gStratOffset + vec2(0.1, 0.9), 1.0);
    }
    #endif

    float phi = TWO_PI * r.x;
    float cosTheta = r.y;
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	// Create an orthogonal basis
	vec3 w = normalize(dir);
	vec3 u = normalize(orthogonal(w));
	vec3 v = normalize(cross(w, u));

	return (cos(phi) * u + sin(phi) * v) * sinTheta + cosTheta * w;
}

////////////////////////////////////////////////////////////////////////////////
/// Generate uniform random direction on unit sphere.
/// PDF = 1 / pi.
/// \return The randomly generated unit vector.
////////////////////////////////////////////////////////////////////////////////
vec3 randomSphereVector()
{
    vec2 r = rand2();

    #if STRATIFIED_SAMPLING
    #if HYBRID_STRATIFIED_SAMPLING
    if(gStratFrame < HYBRID_STRATIFIED_SAMPLING_MAX_FRAME)
    #endif
    {
        r *= 0.1;
        r += gStratOffset;
    }
    #endif

    float phi = TWO_PI * r.x;
    float cosTheta = r.y * 2.0 - 1.0; // [-1, 1]
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	return vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);
}
