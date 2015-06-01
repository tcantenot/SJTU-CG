float gSeed = 0.0;

float rand(float gSeed)
{
    return fract(sin(gSeed)*43758.5453123);
}

float rand()
{
    return rand(gSeed++);
}

vec2 rand2(vec2 n)
{
	float x = dot(n, vec2(1.0, 113.00));
    return fract(sin(vec2(x, x+1.0)) * vec2(13.5453123, 31.1459123));
}

vec2 rand2()
{
    return vec2(rand(), rand());
}
