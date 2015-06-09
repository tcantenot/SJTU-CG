#include "hitinfo.glsl"

float pi = 3.141592;

vec2 r(vec2 v,float y)
{
    return cos(y)*v+sin(y)*vec2(-v.y,v.x);
}

float somestep(float t)
{
    return pow(t, 4.0);
}

vec3 smin(vec3 a, vec3 b)
{
    if (a.x < b.x)
        return a;

    return b;
}

vec3 smax(vec3 a, vec3 b)
{
	if (a.x > b.x)
        return a;

    return b;
}

vec3 sinv(vec3 a)
{
	return vec3(-a.x, a.y, a.z);
}

//repeat around y axis n times
void rp(inout vec3 p, float n) {
	float w = 2.0*pi/n;
	float a = atan(p.z, p.x);
	float r = length(p.xz);
	a = mod(a+pi*.5, w)+pi-pi/n;
	p.xz = r*vec2(cos(a),sin(a));
}

vec3 moebius(vec3 p, vec3 q)
{
  float a = atan(p.z,p.x);
  vec2 p2 = vec2(length(p.xz),p.y);
  p2.x -= q.z;
  p2 = r(p2, a*0.5);
  vec2 p3 = r(p2, pi/4.0);
  vec2 tc = vec2(p3.y,a);
  float d = abs(p2.y)-q.x;
  d = max(d,abs(p2.x)-q.y);
  return vec3(d, tc);
}

vec3 dualmoebius(vec3 p)
{
	float bandSize = 1.5;
	float radius = 5.0;
	float bandThickness = 0.75;
	return smax(moebius(p, vec3(bandSize, bandThickness, radius)), sinv(moebius(p, vec3(bandSize - bandThickness, bandThickness+0.1, radius))));
}

vec3 sphere(vec3 p, float r)
{
    vec3 n = normalize(p);
    vec2 tc = asin(n.xz)/pi + 0.5;
	return vec3(length(p) - r, tc * 2.0);
}

vec3 spheres(vec3 p)
{
	rp(p, 12.0);
	p.x += 5.0;
	return sphere(p, 0.75);
}

float f(vec3 p, inout HitInfo hitInfo)
{
    // FIXME
    float iGlobalTime = 42.0;
	vec2 mouse = vec2(sin(iGlobalTime), cos(iGlobalTime));//iMouse.xy / iResolution.xy;
	//p.xz = r(p.xz, mouse.x);
	p.yz = r(p.yz, 0.1 * iGlobalTime);

    vec3 q = p;
	q.xz = r(q.xz, 0.5 * iGlobalTime);

    hitInfo.id = 1;

	return smin(sphere(p, 3.0), smin(spheres(q), dualmoebius(q))).x;
}

#define HOOK_MAP f
