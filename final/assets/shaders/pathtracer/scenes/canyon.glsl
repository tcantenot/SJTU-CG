#define NoiseTexture uTexture0

#define iChannel0 uTexture2
#define iChannel1 uTexture3
#define iChannel2 uTexture0
#define iChannel3 uTexture4
#define iGlobalTime uTime
#define iResolution uResolution
#define iMouse uMouse

/*#define HIGH_DETAIL*/
/*#define HIGH_QUALITY_NOISE*/

float noise1(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    // Smooth Hermite interpolation
	f = f * f * (3.0 - 2.0 * f);

    const float bias = -100.0;
    vec2 dim = textureSize(NoiseTexture, 0);

    #ifdef HIGH_QUALITY_NOISE
	vec2 uv = p.xy + vec2(37.0, 17.0) * p.z;
	vec2 rg1 = texture(NoiseTexture, (uv + vec2(0.5, 0.5)) / dim, bias).yx;
	vec2 rg2 = texture(NoiseTexture, (uv + vec2(1.5, 0.5)) / dim, bias).yx;
	vec2 rg3 = texture(NoiseTexture, (uv + vec2(0.5, 1.5)) / dim, bias).yx;
	vec2 rg4 = texture(NoiseTexture, (uv + vec2(1.5, 1.5)) / dim, bias).yx;
	vec2 rg = mix(mix(rg1, rg2, f.x), mix(rg3, rg4, f.x), f.y);
    #else
	vec2 uv = p.xy + vec2(37.0, 17.0) * p.z + f.xy;
	vec2 rg = texture(NoiseTexture, (uv + 0.5) / dim, bias).yx;
    #endif

	return mix(rg.x, rg.y, f.z);
}

//-----------------------------------------------------------------------------------

// Fractional Brownian motion
float fbm(vec3 p, const bool normalized)
{
    // Rotation matrix used to improve the fbm by rotating every octave
    const mat3 m = mat3(
        +0.00, +0.80, +0.60,
        -0.80, +0.36, -0.48,
        -0.60, -0.48, +0.64
    );

    float f = 0.0;

    // First octave of noise: 0.5 of amplitude, 1.0 of frequency
    f += 0.5000 * noise1(p); p = m * p * 2.02; // Rotate p and double the frequency

    // Add other octaves of noise
    f += 0.2500 * noise1(p); p = m * p * 2.03;
    f += 0.1250 * noise1(p); p = m * p * 2.01;

	#ifdef HIGH_DETAIL
    f += 0.0625 * noise1(p); p = m * p * 2.04;
    /*f += 0.03125*noise1(p);*/
    #endif

    // Normalization
    if(normalized) f /= 0.9375;

    return f;
}

float displacement(vec3 p)
{
    return fbm(p, false);
}

vec4 texcube(sampler2D sampler, in vec3 p, in vec3 n)
{
	vec4 x = texture(sampler, p.yz);
	vec4 y = texture(sampler, p.zx);
	vec4 z = texture(sampler, p.xy);
	return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))/(abs(n.x)+abs(n.y)+abs(n.z));
}


vec4 texture2DGood(sampler2D sampler, vec2 uv, float bias)
{
    const float c = 1024.0;
    uv = uv * c - 0.5;
    vec2 iuv = floor(uv);
    vec2 f = fract(uv);
	vec4 rg1 = texture(sampler, (iuv+ vec2(0.5,0.5)) / c, bias);
	vec4 rg2 = texture(sampler, (iuv+ vec2(1.5,0.5)) / c, bias);
	vec4 rg3 = texture(sampler, (iuv+ vec2(0.5,1.5)) / c, bias);
	vec4 rg4 = texture(sampler, (iuv+ vec2(1.5,1.5)) / c, bias);
	return mix(mix(rg1,rg2,f.x), mix(rg3,rg4,f.x), f.y);
}
//-----------------------------------------------------------------------------------

float terrain(in vec2 q)
{
	float th = smoothstep(0.0, 0.7, texture(iChannel0, 0.001*q, -100.0).x);
    float rr = smoothstep(0.1, 0.5, texture(iChannel1, 2.0*0.03*q, -100.0).y);
	float h = 1.9;
	#ifdef HIGH_DETAIL
	h += (1.0-0.6*rr)*(1.5-1.0*th) * 0.2*(1.0-texture(iChannel0, 0.03*q, -100.0).x);
	#endif
	h += th*7.0;
    h += 0.3*rr;
    return -h;
}

float terrain2(in vec2 q)
{
	float th = smoothstep(0.0, 0.7, texture2DGood(iChannel0, 0.001*q, -100.0).x);
    float rr = smoothstep(0.1, 0.5, texture2DGood(iChannel1, 2.0*0.03*q, -100.0).y);
	float h = 1.9;
	h += th*7.0;
    return -h;
}


float map(in vec3 p, inout HitInfo hitInfo)
{
	float h = terrain(p.xz);
	float dis = displacement(0.25 * p * vec3(1.0,4.0,1.0));
	dis *= 3.0;
	float t = (dis + p.y - h) * 0.25;//, p.x, h, 0.0);

    hitInfo.id = -1;

    if(t < RM_TMAX)
    {
        hitInfo.id = 0;
    }

    return t;
}
