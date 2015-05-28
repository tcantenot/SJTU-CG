#include "random.glsl"


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
	return abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0)  : vec3(0.0, -v.z, v.y);
}


// Generate random direction on unit hemisphere proportional to cosine-weighted solid angle
vec3 cosineWeightedSample(vec3 dir)
{
    const float TwoPi = 2.0 * 3.141592654;

	vec2 r = rand2n();

	if(Stratify)
    {
        r *= 0.1;
        r+= strat;
        strat = mod(strat + vec2(0.1, 0.9), 1.0);
    }

    float phi = TwoPi * r.x;
    float cosTheta = r.y;
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    vec3 p;
    p.x = cos(phi) * sinTheta;
    p.y = sin(phi) * sinTheta;
    p.z = cosTheta;

	// Create an orthogonal basis
	vec3 o3 = normalize(dir);
	vec3 o1 = normalize(ortho(o3));
	vec3 o2 = normalize(cross(o3, o1));

	return p.x * o1 + p.y * o2 + p.z * o3;
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
    const float TwoPi = 2.0 * 3.141592654;

	vec2 r = rand2n();

    if(Stratify)
    {
        r *= 0.1;
        r += strat;
    }

    float phi = TwoPi * r.x;
    float cosTheta = 1.0 - r.y * (1.0 - cosThetaMax);
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    vec3 p;
    p.x = cos(phi) * sinTheta;
    p.y = sin(phi) * sinTheta;
    p.z = cosTheta;

	// Create an orthogonal basis
	vec3 o3 = normalize(dir);
	vec3 o1 = normalize(ortho(o3));
	vec3 o2 = normalize(cross(o3, o1));

	return p.x * o1 + p.y * o2 + p.z * o3;
}

// Generate uniform random direction on unit hemisphere
// with probability density rho = 1/2pi
vec3 hemisphereSample(vec3 dir)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 r = rand2n();

    float phi = TwoPi * r.x;
    float cosTheta = r.y;
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    vec3 p;
    p.x = cos(phi) * sinTheta;
    p.y = sin(phi) * sinTheta;
    p.z = cosTheta;

	// Create an orthogonal basis
	vec3 o3 = normalize(dir);
	vec3 o1 = normalize(ortho(o3));
	vec3 o2 = normalize(cross(o3, o1));

	return p.x * o1 + p.y * o2 + p.z * o3;
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
