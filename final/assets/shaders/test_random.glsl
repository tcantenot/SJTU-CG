/*#include "pathtracer/random.glsl"*/


#if 1
// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}



// Compound versions of the hashing algorithm I whipped together.
uint hash( uvec2 v ) { return hash( v.x ^ hash(v.y)                         ); }
uint hash( uvec3 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z)             ); }
uint hash( uvec4 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }



// Construct a float with float-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}



// Pseudo-random value in float-open range [0:1].
float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random( vec2  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec3  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec4  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
#endif

float gSeed = 0.0;

float rand(float seed)
{
    return fract(sin(seed)*43758.5453123);
}

float rn(float xx)
{
    float x0=floor(xx);
    float x1=x0+1;
    float v0 = fract(sin (x0*.014686)*31718.927+x0);
    float v1 = fract(sin (x1*.014686)*31718.927+x1);
    return (v0*(1-fract(xx))+v1*(fract(xx)))*2-1*sin(xx);
}

float rand()
{
    /*return rn(gSeed++);*/
    /*return random(gSeed++);*/
    return rand(gSeed++);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    gSeed = uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;
    gSeed *= float(uIterations);

    /*gSeed = uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;*/
    /*gSeed += float(WangHash(uint(uIterations)));*/

    float r = rand();

    /*for(int i = 0; i < 10000; i++)*/
    /*{*/
        /*r = rand();*/
    /*}*/

    vec3 color = vec3(0.0);

    if(r < 0.33)
    {
        color.x = 1.0;
    }
    else if(r < 0.66)
    {
        color.y = 1.0;
    }
    else
    {
        color.z = 1.0;
    }

    fragColor = vec4(color, 1.0);
    float x = fragCoord.x / uResolution.x;
    if(x > 0.5) fragColor = vec4(0.33, 0.33, 0.33, 1.0);
}
