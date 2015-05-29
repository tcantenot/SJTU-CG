float seed = 0.0;
vec2 SEED = vec2(0.0);

float rand(float seed)
{
    return fract(sin(seed)*43758.5453123);
}

float rand()
{
    return rand(seed++);
}

vec2 rand2(vec2 n)
{
	float x = dot(n, vec2(1.0, 113.00));
    return fract(sin(vec2(x, x+1.0)) * vec2(13.5453123, 31.1459123));
}

vec2 rand2()
{
    return vec2(rand(), rand());
    SEED += vec2(1, 1);
    return rand2(SEED);
}

// Van der Corput radical inverse
// see: http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
float radicalInverseVdC(uint bits)
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
vec2 hammersley2d(uint i, const uint N)
{
    const float iN = 1.0 / float(N);
    return vec2(float(i) * iN, radicalInverseVdC(i));
}
