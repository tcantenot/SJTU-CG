float seed = 0.0;
vec2 SEED = vec2(0.0);

float rand()
{
    /*SEED += vec2(0.1, -0.1);*/
    /*return hash2(SEED);*/
    return fract(sin(seed++)*43758.5453123);
}

// 2D hash function
vec2 rand2(vec2 n)
{
	float x = dot(n, vec2(1.0, 113.00));
    return fract(sin(vec2(x, x+1.0)) * vec2(13.5453123, 31.1459123));
}

vec2 rand2n() {
    return vec2(rand(), rand());
    SEED+=vec2(-1,1);
    return rand2(SEED);
};
