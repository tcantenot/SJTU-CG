#version 140

#include "primitives.glsl"
#include "operators.glsl"

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse = vec4(0.0);

out vec4 RenderTarget0;

#define GAMMA_CORRECTION 0

struct HitInfo
{
    float id;
};


float map(vec3 pos)
{
    const float VOID = 1e20;

    float scene = VOID;

    float plane = sdPlaneY(pos+vec3(0, 2, 0));
    float box = sdBox(pos.yzx, vec3(0.1, 0.5, 0.4));
    float sphere = sdSphere(pos.yzx, 1.0);

    /*opRepAngle(pos.zx, 10.0);*/
    opRep1(pos.z, 1.0);

    float cylinder = sdCylinder(pos, vec2(0.1, 0.3));

    scene = opU(plane, scene);
    scene = opU(sphere, scene);
    /*scene = min(box, scene);*/
    /*scene = min(cylinder, scene);*/
    scene = opU(scene, opCombine(box, cylinder, 0.04));

    return scene;
}


vec2 castRay(
    vec3 ro, vec3 rd,
    const float tmin, const float tmax,
    const float precis, const int stepmax,
    inout HitInfo info
)
{
    float t = tmin;

    float m = 1.0;

    for(int i = 0; i < stepmax; i++)
    {
	    float d = map(ro + t * rd);//, info);
        t += d;
        if(d < precis || t > tmax) break;
    }

    if(t > tmax) m =-1.0;

    return vec2(t, m);
}

vec2 castRay(
    vec3 ro, vec3 rd,
    const float tmin, const float tmax,
    const float precis, const int stepmax
)
{
    HitInfo _;
    return castRay(ro, rd, tmin, tmax, precis, stepmax, _);
}

vec3 calcNormal(in vec3 pos)
{
	vec3 eps = vec3(0.001, 0.0, 0.0);
	vec3 normal = vec3(
	    map(pos+eps.xyy) - map(pos-eps.xyy),
	    map(pos+eps.yxy) - map(pos-eps.yxy),
	    map(pos+eps.yyx) - map(pos-eps.yyx)
    );
	return normalize(normal);
}

vec3 render(in vec3 ro, in vec3 rd)
{
    const float PRECIS = 0.0001;
    const float TMIN = 0.1;
    const float TMAX = 50.0;
    const int STEP_MAX = 500;

    vec2 res = castRay(ro, rd, TMIN, TMAX, PRECIS, STEP_MAX);
    float t = res.x;
    float m = res.y;

    vec3 color = vec3(0.8, 0.9, 1.0);
    color = vec3(0.0);

    float ray_len = t;

    if(m > 0)
    {
        vec3 pos = ro + t * rd;
        vec3 normal = calcNormal(pos);
        vec3 ref = reflect(rd, normal);

        // Lighting
        vec3  light = normalize(vec3(-0.6, 0.7, -0.5));
        /*float ambient = clamp(0.5+0.5*normal.y, 0.0, 1.0);*/
        vec3 ambient = vec3(0.2);
        float diffuse = clamp(dot(normal, light), 0.0, 1.0);
        float specular = pow(clamp(dot(ref, light), 0.0, 1.0), 128.0);

        /*diffuse *= softshadow(pos, light, 0.02, 2.5);*/

        color = ambient + diffuse * vec3(1.0, 0.0, 0.0) + specular * vec3(1.0);

    // Test ray with cut_plane:
#define DEBUG_MODE 1
#if DEBUG_MODE == 1

        float cut_plane = (uMouse.y / uResolution.y - 0.1) * 8.0;

        cut_plane = max(0.0, cut_plane);
        if(rd.y * sign(ro.y - cut_plane) < 0.0)
        {
            float d = (ro.y - cut_plane) / -rd.y;
            if(d < ray_len)
            {
                vec3 hit = ro + rd*d;
                float hit_dist = map(hit);
                float iso = fract(hit_dist*5.0);

                vec3 lhs = vec3(.2,.4,.6);
                vec3 rhs = vec3(.2,.2,.4);
                /*lhs = vec3(.5, 0.0, 0.0);*/
                /*rhs = vec3(1.0, 0.0, 0.0);*/
                vec3 dist_color = mix(lhs, rhs, iso);

                dist_color *= 1.0 / (max(0.0, hit_dist) + 0.001);
                /*dist_color = min(vec3(1.0,1.0,1.0),dist_color);*/
                color = mix(color,dist_color, 0.25);
                /*color = dist_color;*/
                ray_len = d;
            }
        }
#endif
    }
    else // Background
    {
        /*vec2 uv = vTexCoord;*/
		/*color = vec3(uv, 0.5 + 0.5 * sin(uTime));*/
    }

	return clamp(color, 0.0, 1.0);
}

mat3 setCamera(vec3 eye, vec3 target, float cr)
{
	vec3 cw = normalize(target - eye);
	vec3 cp = vec3(sin(cr), cos(cr), 0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

mat3 lookat( in vec3 fw, in vec3 up )
{
	fw = normalize(fw);
	vec3 rt = normalize( cross(fw, normalize(up)) );
	return mat3( rt, cross(rt, fw), fw );
}

vec3 scene(vec3 ro, vec3 rd)
{
    vec3 color = render(ro, rd);

    #if GAMMA_CORRECTION
    color = pow(color, vec3(0.4545));
    #endif

    return color;
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    float aspect = uResolution.x / uResolution.y;

	vec2 q = fragCoord.xy / uResolution.xy;
    vec2 p = q * 2.0 - 1.0;
	p.x *= aspect;

    vec2 mo = uMouse.xy/uResolution.xy;
    mo = vec2(0.0);

	float time = 15.0 + uTime;
    time = 42.0;

	// Camera
	vec3 eye = vec3(
        -0.5 + 3.2 * cos(0.1 * time + 6.0 * mo.x),
        1.0 + 2.0 * mo.y,
        0.5 + 3.2 * sin(0.1 * time + 6.0 * mo.x)
    );

	vec3 target = vec3(-0.5, -0.4, 0.5);

    /*eye = vec3(0.0, 10.0, -15.0);*/
    /*target = vec3(0.0, 0.0, 0.0);*/

	// Camera-to-World matrix
    mat3 ca = setCamera(eye, target, 0.0);

    // Ray origin and direction
    float focal = 1.25;
    vec3 ro = eye;
	vec3 rd = ca * normalize(vec3(p.xy, focal));

    // Render scene
    vec3 color = scene(ro, rd);

    RenderTarget0 = vec4(color, 1.0);
}


// ANTI-ALIASING
#if 0
    vec3 tot = vec3(0.0);
    #ifdef ANTI_ALIASING
    for(int i = 0; i < 4; i++)
    {
        vec2 offset = vec2(mod(float(i), 2.0), mod(float(i/2), 2.0)) / 2.0;
    #else
        vec2 offset = vec2(0.0);
    #endif
        /*vec2 xy = (-uResolution.xy + 2.0 * (fragCoord.xy + offset)) / uResolution.y;*/
        vec2 xy = (fragCoord.xy + offset) / uResolution.xy;
        xy = xy * 2.0 - 1.0;
        xy.x *= aspect;

        // camera
        vec3 ro = vec3( 8.5*cos(0.2+.33*time), 5.0+2.0*cos(0.1*time), 8.5*sin(0.1+0.37*time) );
        vec3 ta = vec3( -2.5+3.0*cos(1.2+.41*time), 0.0, 2.0+3.0*sin(2.0+0.38*time) );
        float roll = 0.2*sin(0.1*time);

        // camera tx
        mat3 ca = setLookAt(ro, ta, roll);
        vec3 rd = normalize(ca * vec3(xy.xy,1.75));

        vec3 color = render(ro, rd);

        tot += pow(color, vec3(0.4545));
    #ifdef ANTI_ALIASING
    }
	tot /= 4.0;
    #endif

    color = tot;
#endif

// VIGNETING
#if 0
	vec2 q = fragCoord.xy / uResolution.xy;
    color *= 0.2 + 0.8 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);
#endif

// HIT INFO
#if 0
    // See: https://www.shadertoy.com/view/4s2GWd
    struct HitInfo
    {
        float id;
        vec3 pos;
        float dist;
        vec3 normal;
        vec3 uvw;
    };
#endif
