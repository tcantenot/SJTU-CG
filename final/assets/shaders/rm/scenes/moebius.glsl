#ifndef PI
#define PI 3.14159265359
#endif

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
void rp(inout vec3 p, float n)
{
	float w = 2.0*PI/n;
	float a = atan(p.z, p.x);
	float r = length(p.xz);
	a = mod(a+PI*.5, w)+PI-PI/n;
	p.xz = r*vec2(cos(a),sin(a));
}

vec3 moebius(vec3 p, vec3 q)
{
  float a = atan(p.z,p.x);
  vec2 p2 = vec2(length(p.xz),p.y);
  p2.x -= q.z;
  p2 = r(p2, a*0.5);
  vec2 p3 = r(p2, PI/4.0);
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
    vec2 tc = asin(n.xz) / PI + 0.5;
	return vec3(length(p) - r, tc * 2.0);
}

vec3 spheres(vec3 p)
{
    // TODO: get cell
	rp(p, 12.0);
	p.x += 5.0;
	return sphere(p, 0.75);
}

float map(vec3 p, inout HitInfo hitInfo)
{
    // FIXME
    float iGlobalTime = 42.0;
	vec2 mouse = vec2(sin(iGlobalTime), cos(iGlobalTime));//iMouse.xy / iResolution.xy;
	//p.xz = r(p.xz, mouse.x);
	p.yz = r(p.yz, 65.0 * PI / 180.0);//0.1 * iGlobalTime);

    vec3 q = p;
	q.xz = r(q.xz, 15.0 * PI / 180.0);//0.5 * iGlobalTime);

    hitInfo.id = 1;

    // TODO get id/cell
	return smin(sphere(p, 3.0), smin(spheres(q), dualmoebius(q))).x;
}

Material HookMaterial(HitInfo hitInfo)
{
    int id = hitInfo.id;
    vec3 pos = hitInfo.pos;

    Material mat = MATERIAL(DIFFUSE, vec3(1.0), 0.0, 0.0, vec3(0.0), NO_AS);

    if(id == 1)
    {
        mat.type = REFRACTIVE;
        mat.albedo = vec3(1.0);//vec3(0.9, 0.5, 0.4);
        mat.refractiveIndex = 1.5;
    }

    return mat;
}

void HookCamera(inout Camera camera, Params params)
{
    const float Pi = 3.141592645;

    vec4 mouse = params.mouse;
    vec2 resolution = params.resolution;

    float z = 14.0;
    float ymin = 0.0;
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
