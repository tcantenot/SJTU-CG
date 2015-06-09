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

Material HookMaterial(HitInfo hitInfo)
{
    int id = hitInfo.id;
    vec3 pos = hitInfo.pos;
    vec3 nor = hitInfo.normal;

	vec4 mate = vec4(0.5,0.5,0.5,0.0);
    {
        vec3 uvw = 1.0*pos;

        vec3 bnor;
        float be = 1.0/1024.0;
        float bf = 0.4;
        bnor.x = texcube( iChannel0, bf*uvw+vec3(be,0.0,0.0), nor ).x - texcube( iChannel0, bf*uvw-vec3(be,0.0,0.0), nor ).x;
        bnor.y = texcube( iChannel0, bf*uvw+vec3(0.0,be,0.0), nor ).x - texcube( iChannel0, bf*uvw-vec3(0.0,be,0.0), nor ).x;
        bnor.z = texcube( iChannel0, bf*uvw+vec3(0.0,0.0,be), nor ).x - texcube( iChannel0, bf*uvw-vec3(0.0,0.0,be), nor ).x;
        bnor = normalize(bnor);
        float amo = 0.2  + 0.25*(1.0-smoothstep(0.6,0.7,nor.y) );
        nor = normalize( nor + amo*(bnor-nor*dot(bnor,nor)) );

        vec3 te = texcube( iChannel0, 0.15*uvw, nor ).xyz;
        te = 0.05 + te;
        mate.xyz = 0.6*te;
        mate.w = 1.5*(0.5+0.5*te.x);
        float th = smoothstep( 0.1, 0.4, texcube( iChannel0, 0.002*uvw, nor ).x );
        vec3 dcol = mix( vec3(0.2, 0.3, 0.0), 0.4*vec3(0.65, 0.4, 0.2), 0.2+0.8*th );
        mate.xyz = mix( mate.xyz, 2.0*dcol, th*smoothstep( 0.0, 1.0, nor.y ) );
        mate.xyz *= 0.5;
        float rr = smoothstep( 0.2, 0.4, texcube( iChannel1, 2.0*0.02*uvw, nor ).y );
        mate.xyz *= mix( vec3(1.0), 1.5*vec3(0.25,0.24,0.22)*1.5, rr );
        mate.xyz *= 1.5*pow(texcube( iChannel3, 8.0*uvw, nor ).xyz,vec3(0.5));
        mate = mix( mate, vec4(0.7,0.7,0.7,.0), smoothstep(0.8,0.9,nor.y + nor.x*0.6*te.x*te.x ));


        mate.xyz *= 1.5;
    }

    Material mat;
    mat.type = DIFFUSE;
    mat.albedo = mate.rgb;
    mat.emissive = vec3(0.0);
    mat.refractiveIndex = 0.0;
    mat.roughness = 0.0;
    mat.as = NO_AS;

    return mat;
}

void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 5.0;
    float ymin = -6.0;
    float ymax = 10.0;

    vec3 pos = vec3(0.0, 0.0, z);

    float theta = mapping(vec2(0.0, 1.0), vec2(-Pi, Pi), mouse.x / resolution.x);
    float c = cos(theta);
    float s = sin(theta);

    pos.x = pos.x * c + pos.z * s;
    pos.z = pos.z * c - pos.x * s;
    pos.y = mapping(vec2(0.0, 1.0), vec2(ymin, ymax), mouse.y / resolution.y);

    camera.position = pos;
    camera.target = vec3(0.0);
    camera.roll = 0.0;
    camera.fov = vec2(45.0, 45.0);
    camera.aperture = 0.0;
    camera.focal = 35.0;
}

#define HOOK_MATERIAL(hitInfo) HookMaterial(hitInfo)
#define HOOK_CAMERA(camera, params) HookCamera(camera, params)
