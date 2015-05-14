
// Procedural white noise
// iq: https://www.shadertoy.com/view/ldl3W8
vec2 whiteNoise2(vec2 p)
{
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

// TODO: replace texture lookup by procedural noise
// iq: https://www.shadertoy.com/view/MdBGzG
float noise(vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
#ifndef HIGH_QUALITY_NOISE
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture2D( iChannel2, (uv+ 0.5)/256.0, -100.0 ).yx;
#else
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z);
	vec2 rg1 = texture2D( iChannel2, (uv+ vec2(0.5,0.5))/256.0, -100.0 ).yx;
	vec2 rg2 = texture2D( iChannel2, (uv+ vec2(1.5,0.5))/256.0, -100.0 ).yx;
	vec2 rg3 = texture2D( iChannel2, (uv+ vec2(0.5,1.5))/256.0, -100.0 ).yx;
	vec2 rg4 = texture2D( iChannel2, (uv+ vec2(1.5,1.5))/256.0, -100.0 ).yx;
	vec2 rg = mix( mix(rg1,rg2,f.x), mix(rg3,rg4,f.x), f.y );
#endif
	return mix( rg.x, rg.y, f.z );
}

// iq: https://www.shadertoy.com/view/XsfGD4
float hash(vec2 n)
{
    return fract(sin(dot(n,vec2(1.0,113.0)))*13.5453123);
}

vec2 hash2(vec2 x)
{
	float n = dot(x,vec2(1.0,113.00));
    return fract(sin(vec2(n,n+1.0))*vec2(13.5453123,31.1459123));
}

vec3 hash3(float n)
{
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(13.5453123,31.1459123,37.3490423));
}



#ifndef HIGH_QUALITY_NOISE
float noise( in vec2 x )
{
	//return texture2D( iChannel0, (x+0.5)/256.0 ).x;

	vec2 p = floor(x);
    vec2 f = fract(x);

	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);

	return texture2D( iChannel0, (uv+0.5)/256.0, -100.0 ).x;
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);

	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture2D( iChannel0, (uv+0.5)/256.0, -100.0 ).yx;

	return mix( rg.x, rg.y, f.z );
}
#else
float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

	f =  f*f*(3.0-2.0*f);

	float a = texture2D( iChannel0, (p+vec2(0.5,0.5))/256.0, -100.0 ).x;
	float b = texture2D( iChannel0, (p+vec2(1.5,0.5))/256.0, -100.0 ).x;
	float c = texture2D( iChannel0, (p+vec2(0.5,1.5))/256.0, -100.0 ).x;
	float d = texture2D( iChannel0, (p+vec2(1.5,1.5))/256.0, -100.0 ).x;

	return mix( mix( a, b, f.x ), mix( c, d, f.x ), f.y );

}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);

	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z);
	vec2 rga = texture2D( iChannel0, (uv+vec2(0.5,0.5))/256.0, -100.0 ).yx;
	vec2 rgb = texture2D( iChannel0, (uv+vec2(1.5,0.5))/256.0, -100.0 ).yx;
	vec2 rgc = texture2D( iChannel0, (uv+vec2(0.5,1.5))/256.0, -100.0 ).yx;
	vec2 rgd = texture2D( iChannel0, (uv+vec2(1.5,1.5))/256.0, -100.0 ).yx;

	vec2 rg = mix( mix( rga, rgb, f.x ),
				   mix( rgc, rgd, f.x ), f.y );

	return mix( rg.x, rg.y, f.z );
}
#endif

float fbm( in vec3 p )
{
    return 0.5000*noise(p*1.0)+
           0.2500*noise(p*2.0)+
           0.1250*noise(p*4.0)+
           0.0625*noise(p*8.0);
}

float fbm( in vec2 p )
{
    return 0.5000*noise(p*1.0)+
           0.2500*noise(p*2.0)+
           0.1250*noise(p*4.0)+
           0.0625*noise(p*8.0);
}
