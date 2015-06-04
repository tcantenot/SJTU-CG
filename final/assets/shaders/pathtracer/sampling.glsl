#include "random.glsl"

#ifndef PI
#define PI 3.14159265359
#endif

#ifndef TWO_PI
#define TWO_PI 6.283185307
#endif


const bool Stratify = false;
const bool BiasSampling = true;


int subframe = 0;

vec2 strat=
vec2(
	floor(mod(float(subframe)*1.0,10.)),
	floor(mod(float(subframe)*0.1,10.))
	)/10.0;


////////////////////////////////////////////////////////////////////////////////
/// \brief Construct a vector orthogonal to the given one.
/// See: http://lolengine.net/blog/2013/09/21/picking-orthogonal-vector-combing-coconuts
/// \param v Vector.
/// \param A orthogonal vector to v.
////////////////////////////////////////////////////////////////////////////////
vec3 ortho(vec3 v)
{
	return abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0) : vec3(0.0, -v.z, v.y);
}


// Generate random direction on unit hemisphere proportional to cosine-weighted solid angle
vec3 cosineWeightedSample(vec3 dir)
{
	vec2 r = rand2();

	if(Stratify)
    {
        r *= 0.1;
        r+= strat;
        strat = mod(strat + vec2(0.1, 0.9), 1.0);
    }

    float phi = TWO_PI * r.x;
    float cosTheta = r.y;
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	// Create an orthogonal basis
	vec3 w = normalize(dir);
	vec3 u = normalize(ortho(w));
	vec3 v = normalize(cross(w, u));

	return (cos(phi) * u + sin(phi) * v) * sinTheta + cosTheta * w;
}


////////////////////////////////////////////////////////////////////////////////
/// \brief Generate random direction on unit oriented hemisphere proportional
/// to solid angle in [0, thetaMax].
/// PDF = 1 / (2pi * (1 - cos(thetaMax)),
///
/// \param dir         Orientation of the sampled hemisphere.
/// \param cosThetaMax Cosine of the maximum angle to the sample vector.
///
/// \return The randomly generated unit vector.
////////////////////////////////////////////////////////////////////////////////
vec3 coneSample(vec3 dir, float cosThetaMax)
{
	vec2 r = rand2();

    if(Stratify)
    {
        r *= 0.1;
        r += strat;
    }

    float phi = TWO_PI * r.x;
    float cosTheta = 1.0 - r.y * (1.0 - cosThetaMax);
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	// Create an orthogonal basis
	vec3 w = normalize(dir);
	vec3 u = normalize(ortho(w));
	vec3 v = normalize(cross(w, u));

	return (cos(phi) * u + sin(phi) * v) * sinTheta + cosTheta * w;
}

// Generate uniform random direction on unit hemisphere
// with probability density rho = 1/2pi
vec3 hemisphereSample(vec3 dir)
{
    vec2 r = rand2();

    float phi = TWO_PI * r.x;
    float cosTheta = r.y;
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	// Create an orthogonal basis
	vec3 w = normalize(dir);
	vec3 u = normalize(ortho(w));
	vec3 v = normalize(cross(w, u));

	return (cos(phi) * u + sin(phi) * v) * sinTheta + cosTheta * w;
}

// Generate uniform random direction on unit sphere
vec3 sphereSample()
{
    vec2 r = rand2();

    float phi = TWO_PI * r.x;
    float cosTheta = r.y * 2.0 - 1.0; // [-1, 1]
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	return vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);
}

vec3 randomSampling(vec3 normal, inout vec3 color)
{
    const float Albedo = 1.0;

    vec3 d;
    if(BiasSampling)
    {
        // Biased sampling: cosine weighted
        // Lambertian BRDF = Albedo / PI
        // PDF = cos(angle) / PI
        d = cosineWeightedSample(normal);

        // Modulate color with: BRDF * cos(angle) / PDF = Albedo
        color *= Albedo;
    }
    else
    {
        // Unbiased sampling: uniform over normal-oriented hemisphere
        // Lambertian BRDF = Albedo / PI
        // PDF = 1 / (2 * PI)
        d = hemisphereSample(normal);

        // Modulate color with: BRDF * cos(angle) / PDF = 2 * Albedo * cos(angle)
        color *= 2.0 * Albedo * max(0.0, dot(d, normal));
    }

    return d;
}


// Generate a random point on unit disk with probability density rho = 1/pi
// using a concentric mapping
vec2 diskConcentricSample()
{
    vec2 h = rand2();
    float r1 = h.x;
    float r2 = h.y;

    float r;   // [0, 1]
    float phi; // [0, 2pi]

    // First triangular region
    if(r1 > -r2 && r1 > r2)
    {
        r = r1;
        phi = (PI / 4.0) * (r2 / r1);
    }
    // Second triangular region
    else if(r1 < r2 && r1 > -r2)
    {
        r = r2;
        phi = (PI / 4.0) * (2.0 - r1 / r2);
    }
    // Third triangular region
    else if(r1 < -r2 && r1 < r2)
    {
        r = -r1;
        phi = (PI / 4.0) * (4.0 + r2 / r1);
    }
    // Fourth triangular region
    else if(r1 > r2 && r1 < -r2)
    {
        r = -r2;
        phi = (PI / 4.0) * (6.0 - r1 / r2);
    }

    vec2 p;
    p.x = r * cos(phi);
    p.y = r * sin(phi);

    return p;
}
