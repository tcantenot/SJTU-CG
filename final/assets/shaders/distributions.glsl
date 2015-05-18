/// RANDOM DISTRIBUTIONS ///

#include "random.glsl"

#define RAND2 hash2_3

// Generate a random point on unit disk with probability density rho = 1/pi
// using a polar mapping
vec2 rDiskPolar(vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);

    float r   = sqrt(h.x);   // [0, 1]
    float phi = TwoPi * h.y; // [0, 2pi]

    vec2 p;
    p.x = r * cos(phi);
    p.y = r * sin(phi);

    return p;
}

// Generate a random point on unit disk with probability density rho = 1/pi
// using a concentric mapping
vec2 rDiskConcentric(vec2 seed)
{
    const float Pi = 3.141592654;

    vec2 h = RAND2(seed);
    float r1 = h.x;
    float r2 = h.y;

    float r;   // [0, 1]
    float phi; // [0, 2pi]

    // First triangular region
    if(r1 > -r2 && r1 > r2)
    {
        r = r1;
        phi = (Pi / 4.0) * (r2 / r1);
    }
    // Second triangular region
    else if(r1 < r2 && r1 > -r2)
    {
        r = r2;
        phi = (Pi / 4.0) * (2.0 - r1 / r2);
    }
    // Third triangular region
    else if(r1 < -r2 && r1 < r2)
    {
        r = -r1;
        phi = (Pi / 4.0) * (4.0 + r2 / r1);
    }
    // Fourth triangular region
    else if(r1 > r2 && r1 < -r2)
    {
        r = -r2;
        phi = (Pi / 4.0) * (6.0 - r1 / r2);
    }

    vec2 p;
    p.x = r * cos(phi);
    p.y = r * sin(phi);

    return p;
}

// Generate a random point on sphere ((0, 0, 0), r)
// with probability density rho = 1 / (4 * pi * r^2)
vec3 rSphere(float r, vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);
    float r1 = h.x;
    float r2 = h.y;

    float s = 2.0 * r * sqrt(r2 * (1.0 - r2));
    float phi = TwoPi * r1;

    vec3 p;
    p.x = cos(phi) * s;
    p.y = sin(phi) * s;
    p.z = r * (1.0 - 2.0 * r2);

    return p;
}

// Generate a random point on sphere (c, r)
// with density rho = 1 / (4 * pi * r^2)
vec3 rSphere(vec3 c, float r, vec2 seed)
{
    return c + rSphere(r, seed);
}

// Generate uniform random direction on unit hemisphere
// with probability density rho = 1/2pi
vec3 rHemisphereUniform(vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);

    float phi = TwoPi * h.x;
    float cosTheta = h.y;
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    vec3 p;
    p.x = cos(phi) * sinTheta;
    p.y = sin(phi) * sinTheta;
    p.z = cosTheta;

    return p;
}

// Generate uniform random direction on unit hemisphere proportinal to solid angle
// with probability density rho = 1/(2pi * (1 - cos(thetaMax))
// theta: [0, thetaMax]
vec3 rHemisphereUniform(float thetaMax, vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);

    float cosThetaMax = cos(thetaMax);

    float phi = TwoPi * h.x;
    float cosTheta = 1.0 - h.y * (1.0 - cosThetaMax);
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    vec3 p;
    p.x = cos(phi) * sinTheta;
    p.y = sin(phi) * sinTheta;
    p.z = cosTheta;

    return p;
}

// Generate random direction on unit hemisphere proportinal to cosine-weighted solid angle
// with probability density rho = cos(theta) / pi
// theta: [0, pi]
vec3 rHemisphereCosine(vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);

    float phi = TwoPi * h.x;
    float s = sqrt(1.0 - h.y);

    vec3 p;
    p.x = cos(phi) * s;
    p.y = sin(phi) * s;
    p.z = sqrt(h.y);

    return p;
}

// Generate random direction on unit hemisphere proportinal to cosine-weighted solid angle
// with probability density rho = cos(theta) / (pi * (sin(thetaMax))^2)
// theta: [0, thetaMax]
vec3 rHemisphereCosine(float thetaMax, vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);

    float sinThetaMax = sin(thetaMax);

    float phi = TwoPi * h.x;
    float s = sinThetaMax * sqrt(h.y);

    vec3 p;
    p.x = cos(phi) * s;
    p.y = sin(phi) * s;
    p.z = sqrt(1.0 - h.y * sinThetaMax * sinThetaMax);

    return p;
}

// Generate random direction on unit hemisphere proportinal to cosine lobe around normal
// with probability density rho = ((n+1)/2pi) * (cos(theta))^n
// theta: [0, pi]
// => General formula:
//  n = 0 -> rHemisphereUniform
//  n = 1 -> rHemisphereCosine
vec3 rHemisphereGeneral(float n, vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);

    float phi = TwoPi * h.x;
    float cosTheta = pow(h.y, 1.0 / (n + 1.0));
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    vec3 p;
    p.x = cos(phi) * sinTheta;
    p.y = sin(phi) * sinTheta;
    p.z = cosTheta;

    return p;
}

// Generate random direction on unit hemisphere proportinal to cosine lobe around normal
// with probability density rho = ((n+1)/2pi) * (cos(theta))^n/(1-(cos(thetaMax))^(n+1))
// theta: [0, thetaMax]
// => General formula:
//  n = 0 -> rHemisphereUniform
//  n = 1 -> rHemisphereCosine
vec3 rHemisphereGeneral(float thetaMax, float n, vec2 seed)
{
    const float TwoPi = 2.0 * 3.141592654;

    vec2 h = RAND2(seed);

    float cosThetaMax = cos(thetaMax);

    float phi = TwoPi * h.x;
    float cosTheta = pow(1.0 - h.y * (1.0 - pow(cosThetaMax, n + 1.0)), 1.0 / (n + 1.0));
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    vec3 p;
    p.x = cos(phi) * sinTheta;
    p.y = sin(phi) * sinTheta;
    p.z = cosTheta;

    return p;
}

#undef RAND2
