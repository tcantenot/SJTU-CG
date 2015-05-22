// 1D random (hash) function
float rand(vec2 n)
{
    return fract(sin(dot(n, vec2(12.9898, 78.233))) * 43758.5453);
}

// 1D hash function
float hash(vec2 n)
{
    return fract(sin(dot(n, vec2(1.0, 113.0))) * 13.5453123);
}

// 2D hash function
vec2 hash2(vec2 n)
{
	float x = dot(n, vec2(1.0, 113.00));
    return fract(sin(vec2(x, x+1.0)) * vec2(13.5453123, 31.1459123));
}

// 3D hash function
vec3 hash3(vec2 n)
{
	float x = dot(n, vec2(1.0, 113.00));
    return fract(sin(vec3(x, x+1.0, x+2.0)) * vec3(13.5453123, 31.1459123, 37.3490423));
}

// Better 2D hash function
vec2 hash2_3(vec2 seed)
{
    return hash3(hash(seed) * seed).yx;
}

// TODO: try these
#if 0
float hash1( float n ) { return fract(43758.5453123*sin(n)); }
float hash1( vec2  n ) { return fract(43758.5453123*sin(dot(n,vec2(1.0,113.0)))); }
vec2  hash2( float n ) { return fract(43758.5453123*sin(vec2(n,n+1.0))); }
vec3  hash3( vec2  n ) { return fract(43758.5453123*sin(dot(n,vec2(1.0,113.0))+vec3(0.0,1.0,2.0))); }
vec4  hash4( vec2  n ) { return fract(43758.5453123*sin(dot(n,vec2(1.0,113.0))+vec4(0.0,1.0,2.0,3.0))); }
#endif


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


// Generate a "random" TBN matrix
mat3 randomTBN(vec3 normal, vec2 seed)
{
    vec3 rvec = normalize(hash3(seed)) * 2.0 - 1.0;
    vec3 tangent = normalize(rvec - normal * dot(rvec, normal));
    vec3 bitangent = cross(normal, tangent);
    return mat3(tangent, bitangent, normal);
}
