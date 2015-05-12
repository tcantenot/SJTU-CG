#version 140

#include "primitives.glsl"
#include "operators.glsl"

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec2 uMouse = vec2(0.0);

out vec4 RenderTarget0;


vec2 addToScene(vec2 d1, vec2 d2)
{
	return (d1.x < d2.x) ? d1 : d2;
}

float addToScene(float d1, float d2, inout bool first)
{
	first = d1 < d2;
    return first ? d1 : d2;
}

float addToScene(float d1, float d2)
{
    bool _;
    return addToScene(d1, d2, _);
}

#if 0
vec2 addToScene(vec2 obj1, vec2 obj2, float dmin)
{
    float d1 = obj1.x;
    float d2 = obj2.x;

    int id1 = int(obj1.y);
    int id2 = int(obj2.y);

    // Perform optimization based on dmin
    // -> use an array of previous distances
    // => see paper
    // ...

    int id;
    float d = opU(d1, d2, id);

    vec2 obj = (id == 0) ? obj1 : obj2;

    return obj;
}
#endif

//----------------------------------------------------------------------

struct HitInfo
{
    float id;
};

struct Material
{
    vec3 diffuse;
    float Ka;
    vec3 specular;
    float shininess;
};

const Material materials[] = Material[]
(
    Material(vec3(0.2, 0.8, 0.2), 0.2, vec3(1.0, 1.0, 1.0), 60.0),
    Material(vec3(0.2, 0.8, 0.2), 0.2, vec3(1.0, 1.0, 1.0), 60.0)
);

float map(vec3 pos, inout HitInfo info)
{
    const float VOID = 1e20;

    float scene = VOID;
    bool b = false;
    info.id = 1e20;

    scene = addToScene(scene, sdPlaneY(pos), b);
    /*info.id = b ? info.id : PLANE_ID;*/

#if 0
	scene = addToScene(scene, vec2(sdSphere(pos-vec3(0.0,0.25, 0.0), 0.25), 46.9));
    scene = addToScene(scene, vec2(sdBox(pos-vec3(1.0,0.25, 0.0), vec3(0.25)), 3.0));
    scene = addToScene(scene, vec2(udRoundBox(pos-vec3(1.0,0.25, 1.0), vec3(0.15), 0.1), 41.0));
	scene = addToScene(scene, vec2(sdTorus(pos-vec3(0.0,0.25, 1.0), vec2(0.20,0.05)), 25.0));
    scene = addToScene(scene, vec2(sdCapsule(pos,vec3(-1.3,0.20,-0.1), vec3(-1.0,0.20,0.2), 0.1), 31.9));
	scene = addToScene(scene, vec2(sdTriPrism(pos-vec3(-1.0,0.25,-1.0), vec2(0.25,0.05)),43.5));
	scene = addToScene(scene, vec2(sdCylinder(pos-vec3(1.0,0.30,-1.0), vec2(0.1,0.2)), 8.0));
	scene = addToScene(scene, vec2(sdCone(pos-vec3(0.0,0.50,-1.0), vec3(0.5,0.5,0.3)), 55.0));
	scene = addToScene(scene, vec2(sdTorus82(pos-vec3(0.0,0.25, 2.0), vec2(0.20,0.05)),50.0));
	scene = addToScene(scene, vec2(sdTorus88(pos-vec3(-1.0,0.25, 2.0), vec2(0.20,0.05)),43.0));
	scene = addToScene(scene, vec2(sdCylinder6(pos-vec3(1.0,0.30, 2.0), vec2(0.1,0.2)), 12.0));
	scene = addToScene(scene, vec2(sdHexPrism(pos-vec3(-1.0,0.20, 1.0), vec2(0.25,0.05)),17.0));

    scene = addToScene(scene, vec2(opS(
		             udRoundBox(pos-vec3(-2.0,0.2, 1.0), vec3(0.15),0.05),
	                 sdSphere(pos-vec3(-2.0,0.2, 1.0), 0.25)), 13.0));
    scene = addToScene(scene, vec2(opS(
		             sdTorus82(pos-vec3(-2.0,0.2, 0.0), vec2(0.20,0.1)),
	                 sdCylinder(opRep(vec3(atan(pos.x+2.0,pos.z)/6.2831,
											  pos.y,
											  0.02+0.5*length(pos-vec3(-2.0,0.2, 0.0))),
									     vec3(0.05,1.0,0.05)), vec2(0.02,0.6))), 51.0));
	scene = addToScene(scene, vec2(0.7*sdSphere(pos-vec3(-2.0,0.25,-1.0), 0.2) +
					                   0.03*sin(50.0*pos.x)*sin(50.0*pos.y)*sin(50.0*pos.z),
                                       65.0));

    {
        const float a = 10.0;
        vec3 twist = opTwist(pos-vec3(-2.0, 0.25, 2.0), a, 10.0);
        float lip = opTwistLip(a);
        lip = 0.5;
	    scene = addToScene(scene, vec2(lip * sdTorus(twist,vec2(0.20,0.05)), 46.7));
    }
#endif

    return scene;
}

vec2 map(vec3 pos)
{
    const vec2 VOID = vec2(1e20);

    vec2 scene = VOID;

    // Checkboard plane
    scene = addToScene(scene, vec2(sdPlaneY(pos+vec3(0, 2, 0)), 1.0));

    float box = sdBox(pos.yzx, vec3(0.1, 0.9, 0.4));
    float cylinder = sdCylinder(pos, vec2(0.1, 0.3));

    scene = addToScene(scene, vec2(box, 20.0));
    scene = addToScene(scene, vec2(cylinder, 20.0));

    return scene;

#if 0
    vec3 p = pos;
    p.x = mod(p.x+10, 20) - 10;
    /*float c = opRep1(pp.z, 10.0);*/
    /*scene = addToScene(scene, vec2(sdSphere(pp-vec3(0.0,0.25, 0.0), 0.25), 46.9));*/
    scene = addToScene(scene, vec2(sdSphere(p-vec3(0.0, 0.25, 0.0), 0.25), 46.9));

    scene = addToScene(scene, vec2(sdBox(pos-vec3(1.0,0.25, 0.0), vec3(0.25)), 3.0));
    scene = addToScene(scene, vec2(udRoundBox(pos-vec3(1.0,0.25, 1.0), vec3(0.15), 0.1), 41.0));
	scene = addToScene(scene, vec2(sdTorus(pos-vec3(0.0,0.25, 1.0), vec2(0.20,0.05)), 25.0));
    scene = addToScene(scene, vec2(sdCapsule(pos,vec3(-1.3,0.20,-0.1), vec3(-1.0,0.20,0.2), 0.1), 31.9));
	scene = addToScene(scene, vec2(sdTriPrism(pos-vec3(-1.0,0.25,-1.0), vec2(0.25,0.05)),43.5));
	scene = addToScene(scene, vec2(sdCylinder(pos-vec3(1.0,0.30,-1.0), vec2(0.1,0.2)), 8.0));
	scene = addToScene(scene, vec2(sdCone(pos-vec3(0.0,0.50,-1.0), vec3(0.5,0.5,0.3)), 55.0));
	scene = addToScene(scene, vec2(sdTorus82(pos-vec3(0.0,0.25, 2.0), vec2(0.20,0.05)),50.0));
	scene = addToScene(scene, vec2(sdTorus88(pos-vec3(-1.0,0.25, 2.0), vec2(0.20,0.05)),43.0));
	scene = addToScene(scene, vec2(sdCylinder6(pos-vec3(1.0,0.30, 2.0), vec2(0.1,0.2)), 12.0));
	scene = addToScene(scene, vec2(sdHexPrism(pos-vec3(-1.0,0.20, 1.0), vec2(0.25,0.05)),17.0));

    scene = addToScene(scene, vec2(opS(
		             udRoundBox(pos-vec3(-2.0,0.2, 1.0), vec3(0.15),0.05),
	                 sdSphere(pos-vec3(-2.0,0.2, 1.0), 0.25)), 13.0));
    scene = addToScene(scene, vec2(opS(
		             sdTorus82(pos-vec3(-2.0,0.2, 0.0), vec2(0.20,0.1)),
	                 sdCylinder(opRep(vec3(atan(pos.x+2.0,pos.z)/6.2831,
											  pos.y,
											  0.02+0.5*length(pos-vec3(-2.0,0.2, 0.0))),
									     vec3(0.05,1.0,0.05)), vec2(0.02,0.6))), 51.0));
	scene = addToScene(scene, vec2(0.7*sdSphere(pos-vec3(-2.0,0.25,-1.0), 0.2) +
					                   0.03*sin(50.0*pos.x)*sin(50.0*pos.y)*sin(50.0*pos.z),
                                       65.0));

    {
        const float a = 10.0;
        vec3 twist = opTwist(pos-vec3(-2.0, 0.25, 2.0), a, 10.0);
        float lip = opTwistLip(a);
        lip = 0.5;
	    scene = addToScene(scene, vec2(lip * sdTorus(twist,vec2(0.20,0.05)), 46.7));
    }
#endif

    return scene;
}


vec2 castRay(vec3 ro, vec3 rd, const float tmin, const float tmax, const float precis, inout HitInfo info)
{
    float t = tmin;

    float m = -1.0;

    for(int i = 0; i < 50; i++)
    {
	    vec2 res = map(ro + t * rd);//, info);

        if(res.x < precis || t > tmax) break;

        t += res.x;

	    m = res.y;
    }

    if(t > tmax) m =-1.0;

    return vec2(t, m);
}

vec2 castRay(vec3 ro, vec3 rd, const float tmin, const float tmax, const float precis)
{
    HitInfo _;
    return castRay(ro, rd, tmin, tmax, precis, _);
}


float softshadow(vec3 ro, vec3 rd, const float mint, const float tmax)
{
	float res = 1.0;
    float t = mint;
    for(int i = 0; i < 16; i++)
    {
		float h = map(ro + t * rd).x;
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.10);
        if(h < 0.001 || t > tmax) break;
    }
    return clamp(res, 0.0, 1.0);

}

vec3 calcNormal(in vec3 pos)
{
	vec3 eps = vec3(0.001, 0.0, 0.0);
	vec3 normal = vec3(
	    map(pos+eps.xyy).x - map(pos-eps.xyy).x,
	    map(pos+eps.yxy).x - map(pos-eps.yxy).x,
	    map(pos+eps.yyx).x - map(pos-eps.yyx).x
    );
	return normalize(normal);
}

float calcAO(in vec3 pos, in vec3 normal)
{
	float ao = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++)
    {
        float hr = 0.01 + 0.12 * float(i) / 4.0;
        vec3 aopos =  normal * hr + pos;
        float dd = map(aopos).x;
        ao += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0*ao, 0.0, 1.0);
}




vec3 render(in vec3 ro, in vec3 rd)
{
    vec3 color = vec3(0.8, 0.9, 1.0);
    const float PRECIS = 0.001;
    vec2 res = castRay(ro, rd, 1.0, 50.0, PRECIS);
    float t = res.x;
	float m = res.y;

    if(m > -0.5)
    {
        vec3 pos = ro + t * rd;
        vec3 normal = calcNormal(pos);
        vec3 ref = reflect(rd, normal);

        // material
		color = 0.45 + 0.3 * sin(vec3(0.05, 0.08, 0.10) * (m - 1.0));

        // Checkboard floor
        if(m < 1.5)
        {

            float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
            color = 0.4 + 0.1 * f * vec3(1.0);
        }

        // Lighting
        float ao = calcAO(pos, normal);
        ao = 1.0;
		vec3  light = normalize(vec3(-0.6, 0.7, -0.5));
		float ambient = clamp(0.5+0.5*normal.y, 0.0, 1.0);
        float diffuse = clamp(dot(normal, light), 0.0, 1.0);
        float bac = clamp(dot(normal, normalize(vec3(-light.x,0.0,-light.z))), 0.0, 1.0)*clamp(1.0-pos.y,0.0,1.0);
        float dom = smoothstep(-0.1, 0.1, ref.y);
        float fresnel = pow(clamp(1.0+dot(normal, rd),0.0,1.0), 2.0);
		float specular = pow(clamp(dot(ref, light), 0.0, 1.0),16.0);

        diffuse *= softshadow(pos, light, 0.02, 2.5);
        dom *= softshadow(pos, ref, 0.02, 2.5);

		vec3 brdf = vec3(0.0);
        brdf += 1.20 * diffuse * vec3(1.00, 0.90, 0.60);
		brdf += 1.20 * specular * vec3(1.00, 0.90, 0.60) * diffuse;
        brdf += 0.30 * ambient * vec3(0.50, 0.70, 1.00) * ao;
        /*brdf += 0.40*dom*vec3(0.50,0.70,1.00)*ao;*/
        /*brdf += 0.30*bac*vec3(0.25,0.25,0.25)*ao;*/
        /*brdf += 0.40*fresnel*vec3(1.00,1.00,1.00)*ao;*/
		/*brdf += 0.02;*/
        color = color*brdf;

        // Fog
        /*const float fogFactor = 0.01;*/
        /*const vec3 fogColor = vec3(0.8, 0.9, 1.0);*/
        /*color = mix(color, fogColor, 1.0 - exp(-fogFactor*t*t));*/
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

vec3 scene(vec3 ro, vec3 rd)
{
    vec3 color = render(ro, rd);
	color = pow(color, vec3(0.4545));
    return color;
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;

	vec2 q = fragCoord.xy / uResolution.xy;
    vec2 p = q * 2.0 - 1.0;
	p.x *= uResolution.x / uResolution.y;

    vec2 mo = uMouse.xy/uResolution.xy;

	float time = 15.0 + uTime;
    time = 20.0;

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
    float focal = 2.5;
    vec3 ro = eye;
	vec3 rd = ca * normalize(vec3(p.xy, focal));

    // Render scene
    vec3 color = scene(ro, rd);

    RenderTarget0 = vec4(color, 1.0);
}
