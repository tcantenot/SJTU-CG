/// RANDOM/HASH FUNCTIONS ///

// Global seed to initialize in the main function
float gRandSeed = 0.0;


////////////////////////////////////////////////////////////////////////////////
///                           SEED INITIALIZATION                            ///
////////////////////////////////////////////////////////////////////////////////

void randomSeedInit(vec2 pixel, vec2 resolution, int iteration)
{
    gRandSeed = resolution.y * pixel.x / resolution.x + pixel.y / resolution.y;
    gRandSeed *= float(iteration);
}


////////////////////////////////////////////////////////////////////////////////
///                           RAND/HASH FUNCTIONS                            ///
////////////////////////////////////////////////////////////////////////////////

float rand(float);
float randHashInt(float);

float rand()
{
    /*return rand(gRandSeed++);*/
    return randHashInt(gRandSeed++);
}

vec2 rand2()
{
    return vec2(rand(), rand());
}

float rand(float seed)
{
    return fract(sin(seed) * 43758.5453123);
}

// http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl#
float rand(vec2 n)
{
    return fract(sin(dot(n.xy, vec2(12.9898, 78.233))) * 43758.5453);
}


////////////////////////////////////////////////////////////////////////////////
///                        OTHER RAND/HASH FUNCTIONS                         ///
////////////////////////////////////////////////////////////////////////////////

float hash1(float n)
{
    return fract(43758.5453123 * sin(n));
}

float hash1(vec2 n)
{
    return fract(43758.5453123 * sin(dot(n, vec2(1.0, 113.0))));
}

vec2 hash2(float n)
{
    return fract(43758.5453123 * sin(vec2(n, n+1.0)));
}

vec2 hash2(vec2 n)
{
	float x = dot(n, vec2(1.0, 113.00));
    return fract(sin(vec2(x, x+1.0)) * vec2(13.5453123, 31.1459123));
}

vec3 hash3(vec2 n)
{
    return fract(43758.5453123 *
        sin(dot(n, vec2(1.0, 113.0)) + vec3(0.0, 1.0, 2.0)));
}

vec4 hash4(vec2 n)
{
    return fract(43758.5453123 *
        sin(dot(n, vec2(1.0, 113.0)) + vec4(0.0, 1.0, 2.0, 3.0)));
}

////////////////////////////////////////////////////////////////////////////////
///               RANDOM FLOAT BASED ON INTEGER HASH FUNCTION                ///
////////////////////////////////////////////////////////////////////////////////

// http://amindforeverprogramming.blogspot.com/2013/07/random-floats-in-glsl-330.html

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint _oneAtATimeHash(uint x)
{
    x += (x << 10u);
    x ^= (x >>  6u);
    x += (x <<  3u);
    x ^= (x >> 11u);
    x += (x << 15u);
    return x;
}

#define _hash(x) _oneAtATimeHash(x)

// Compound versions of the hashing algorithm
uint _hash(uvec2 v) { return _hash(v.x ^ _hash(v.y)                          ); }
uint _hash(uvec3 v) { return _hash(v.x ^ _hash(v.y) ^ _hash(v.z)             ); }
uint _hash(uvec4 v) { return _hash(v.x ^ _hash(v.y) ^ _hash(v.z) ^ _hash(v.w)); }

// Construct a float with float-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value
// below 1.0.
float _floatConstruct(uint m)
{
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;  // Keep only mantissa bits (fractional part)
    m |= ieeeOne;       // Add fractional part to 1.0

    float  f = uintBitsToFloat(m); // Range [1, 2]
    return f - 1.0;                // Range [0, 1]
}

// Pseudo-random value in float-open range [0, 1].
float randHashInt(float x) { return _floatConstruct(_hash(floatBitsToUint(x))); }
float randHashInt(vec2  v) { return _floatConstruct(_hash(floatBitsToUint(v))); }
float randHashInt(vec3  v) { return _floatConstruct(_hash(floatBitsToUint(v))); }
float randHashInt(vec4  v) { return _floatConstruct(_hash(floatBitsToUint(v))); }

#undef _hash


////////////////////////////////////////////////////////////////////////////////
///                             HAMMERSLEY 2D                                ///
////////////////////////////////////////////////////////////////////////////////

// Van der Corput radical inverse
// see: http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
float _radicalInverseVdC(uint bits)
{
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}

// Hammersley 2D point set
// see: http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
vec2 Hammersley2D(uint i, const uint N)
{
    const float iN = 1.0 / float(N);
    return vec2(float(i) * iN, _radicalInverseVdC(i));
}


////////////////////////////////////////////////////////////////////////////////
///                             RANDOM TBN                                   ///
////////////////////////////////////////////////////////////////////////////////

// Generate a "random" TBN matrix
mat3 randomTBN(vec3 normal, vec2 seed)
{
    vec3 rvec = normalize(hash3(seed)) * 2.0 - 1.0;
    vec3 tangent = normalize(rvec - normal * dot(rvec, normal));
    vec3 bitangent = cross(normal, tangent);
    return mat3(tangent, bitangent, normal);
}
