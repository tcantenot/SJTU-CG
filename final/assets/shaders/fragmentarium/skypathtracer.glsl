#include "sunsky.glsl"

#define MULTIPLICITY 1
#define SAMPLES 4
#define MAXDEPTH 8


#include "../distance_fields.glsl"
const float NONE = 1e20;

// Distance to object at which raymarching stops.
uniform float Detail = -4.0;//slider[-7,-2.3,0];

// Lower this if the system is missing details
uniform float FudgeFactor = 1.0; //slider[0,1,1];

float minDist = pow(10.0, Detail);

// Maximum number of  raymarching steps.
uniform int MaxRaySteps = 500;  //slider[0,56,2000]
vec4 orbitTrap = vec4(10000.0);


#if 1

// 2D hash function
vec2 rand2(vec2 n)
{
	float x = dot(n, vec2(1.0, 113.00));
    return fract(sin(vec2(x, x+1.0)) * vec2(13.5453123, 31.1459123));
}



float DE(vec3 p) // Must be implemented in other file
{
    float scene = NONE;

    int id = -1;

    p -= vec3(50.0, 20.0, 30.0);

    float sphere = NONE;

    sphere = sdSphere(p-vec3(90.0, 0.0, 0.0), 30.0);

    scene = opU(scene, sphere, id, 3, id);

    opRep1(p.x, 150.0);
    /*opRep1(p.z, 3);*/

    /*sphere = sdBox(p, vec3(40.0));*/
    sphere = sdSphere(p, 40.0);
    /*float box = sdBox(p+vec3(1.2, 0.0, 0.0), vec3(0.5));*/
    scene = opU(scene, sphere, id, 2, id);

    return scene;
}


vec3 normal(vec3 pos, float normalDistance) {
	normalDistance = max(normalDistance*0.5, 1.0e-7);
	vec3 e = vec3(0.0,normalDistance,0.0);
	vec3 n = vec3(DE(pos+e.yxx)-DE(pos-e.yxx),
		DE(pos+e.xyx)-DE(pos-e.xyx),
		DE(pos+e.xxy)-DE(pos-e.xxy));
	n = normalize(n);
	return n;
}

// This is the pure color of object(in white light)
uniform vec3 BaseColor = vec3(1.0); //color[1.0,1.0,1.0];
// Determines the mix between pure light coloring and pure orbit trap coloring
uniform float OrbitStrength = 0.5; //slider[0,0,1]

// Closest distance to YZ-plane during orbit
uniform vec4 X = vec4(0.7, 0.5, 0.5, 0.6); //color[-1,0.7,1,0.5,0.6,0.6];

// Closest distance to XZ-plane during orbit
uniform vec4 Y = vec4(0.4, 1.0, 0.6, 0.0);// color[-1,0.4,1,1.0,0.6,0.0];

// Closest distance to XY-plane during orbit
uniform vec4 Z = vec4(0.5, 0.8, 0.78, 1.0);// color[-1,0.5,1,0.8,0.78,1.0];

// Closest distance to  origin during orbit
uniform vec4 R = vec4(0.12, 0.4, 0.7, 1.0); //color[-1,0.12,1,0.4,0.7,1.0];

uniform bool CycleColors = false;// checkbox[false]
uniform float Cycles = 1.1; //slider[0.1,1.1,32.3]

#define PI  3.14159265358979323846264

float rand(vec2 co){
	// implementation found at: lumina.sourceforge.net/Tutorials/Noise.html
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

#ifdef  providesColor
vec3 baseColor(vec3 point, vec3 normal);
#endif

bool trace(vec3 from, vec3 dir, inout vec3 hit, inout vec3 hitNormal)
{
	vec3 direction = normalize(dir);
	float eps = minDist;
	float dist = 1000.0;

	float totalDist = 0.0;
	for(int steps = 0; steps < MaxRaySteps && dist > eps; steps++)
    {
		hit = from + totalDist * direction;
		dist = DE(hit) * FudgeFactor;
		totalDist += dist;
	}

	if(dist < eps)
    {
		hit = from + (totalDist - eps) * direction;
		hitNormal = normal(hit, eps);
		return true;
	}

	return false;
}

uniform float Reflectivity = 0.0; //slider[0,0.2,1.0]
uniform bool DebugLast = false; //checkbox[false]
uniform bool Stratify = true; //checkbox[false]
uniform int RayDepth = 4; //slider[0,2,5] Locked
uniform float Albedo = 1.0; //slider[0,1,1]

vec3 ortho(vec3 v) {
	//  See : http://lolengine.net/blog/2013/09/21/picking-orthogonal-vector-combing-coconuts
	return abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0)  : vec3(0.0, -v.z, v.y);
}

//FIXME
int subframe = 0;
vec2 viewCoord = gl_FragCoord.xy;

vec2 cx=
vec2(
	floor(mod(float(subframe)*1.0,10.)),
	floor(mod(float(subframe)*0.1,10.))
	)/10.0;

vec2 seed = viewCoord*(float(subframe)+1.0);

vec2 rand2n() {
	seed+=vec2(-1,1);
	return rand2(seed);
};


vec3 getSampleBiased(vec3  dir, float power)
{
	dir = normalize(dir);
	// create orthogonal vector
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));

	// Convert to spherical coords aligned to dir;
	vec2 r = rand2n();

	if(Stratify) { r*=0.1; r+= cx;  cx = mod(cx + vec2(0.1,0.9),1.0);}
	r.x=r.x*2.*PI;

	// This is  cosine^n weighted.
	// See, e.g. http://people.cs.kuleuven.be/~philip.dutre/GI/TotalCompendium.pdf
	// Item 36
	/*r.y= pow(max(r.y, 0.0001), 1.0/(power+1.0));*/ // <- segfault...
    power += 1.001;
    float p = 1.0 / power;
	r.y = pow(r.y, p);

	float oneminus = sqrt(1.0-r.y*r.y);
	vec3 sdir = cos(r.x)*oneminus*o1+ sin(r.x)*oneminus*o2+ r.y*dir;

	return sdir;
}

vec3 getConeSample(vec3 dir, float extent) {
	// Create orthogonal vector(fails for z,y = 0)
	dir = normalize(dir);
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));

	// Convert to spherical coords aligned to dir
	vec2 r =  rand2n();

	if(Stratify) {r*=0.1; r+= cx;}
	r.x=r.x*2.*PI;
	r.y=1.0-r.y*extent;

	float oneminus = sqrt(1.0-r.y*r.y);
	return cos(r.x)*oneminus*o1+sin(r.x)*oneminus*o2+r.y*dir;
}

vec3 getColor() { return vec3(1.0, 0.0 ,1.0); }

float rand() { return rand(viewCoord*(float(subframe)+1.0)); }


uniform bool BiasedSampling = true;// checkbox[true]
uniform bool DirectLight = true; //checkbox[true]

vec3 radiance(vec3 from, vec3 dir)
{
	vec3 hit = vec3(0.0);
	vec3 hitNormal = vec3(0.0);

	vec3 color = vec3(1.0);
	vec3 direct = vec3(0.0);
	for(int i = 0; i < RayDepth; i++)
	{
		if(trace(from, dir, hit, hitNormal))
        {
			// We hit something

            // Diffuse material
			if(rand() > Reflectivity)
            {
				color *= getColor();

				//color *=(1.0-Reflectivity);
				if(!BiasedSampling)
                {
					// Unbiased sampling:
					// PDF = 1/(2*PI), BRDF = Albedo/PI
					dir = getConeSample(hitNormal,1.0);
					// modulate color with: BRDF*CosAngle/PDF
					color *= 2.0 * Albedo * max(0.0, dot(dir,hitNormal));
				}
				else
                {
					// Biased sampling (cosine weighted):
					// PDF = CosAngle / PI, BRDF = Albedo/PI
                    dir =getSampleBiased(hitNormal, 1.0);

					// modulate color	 with: BRDF*CosAngle/PDF
					color *= Albedo;
				}

				// Direct
				if(DirectLight)
                {
					vec3 a;
					vec3 b;
					vec3 sunSampleDir = getConeSample(sunDirection, 1.0-sunAngularDiameterCos);
					float sunLight = dot(hitNormal, sunSampleDir);
					if(sunLight>0.0 && !trace(hit+ hitNormal*3.0*minDist,sunSampleDir,a,b))
                    {
						direct += color*sun(sunSampleDir)*sunLight *1E-5;
					}
				}
			}
            // Specular material
			else
            {
				/*color *= getColor();*/
				//color *=Reflectivity;
				dir = reflect(dir, hitNormal);
				color *= max(0.0, dot(dir, hitNormal));
			}

			// Choose new starting point for ray
			from =  hit + hitNormal * minDist * 8.0;
		}
        // We hit the background
        else
        {
			if(DebugLast && i != RayDepth-1)
            {
				return vec3(0.0);
			}

			if(!DirectLight)
            {
                return color * sunsky(dir);
            }

			return direct + color * (i > 0 ? sky(dir) : sunsky(dir));
		}
	}

	return direct;
}
#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    float time = uTime;
    time = 42.0;

	float seed = time + uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;

	vec2 uv = 2. * fragCoord.xy / uResolution.xy - 1.;

	vec3 camPos = vec3((2. *(uMouse.xy==vec2(0.)?.5*uResolution.xy:uMouse.xy) / uResolution.xy - 1.) * vec2(48., 40.) + vec2(50., 40.8), 169.);

	vec3 cz = normalize(vec3(50., 40., 81.6) - camPos);
	vec3 cx = vec3(1., 0., 0.);
	vec3 cy = normalize(cross(cx, cz)); cx = cross(cz, cy);
	vec3 color = vec3(0.);

    vec2 pixel = fragCoord;
    vec2 resolution = uResolution;

    for(int k = 0; k < MULTIPLICITY; ++k)
    {
        float npaths = SAMPLES;
        float aa = float(npaths) / 2.0;
        for(int i = 0; i < npaths; ++i)
        {
            vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;

            vec2 SEED = pixel + offset;

            // Screen coords with antialiasing
            vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;

            #if DEBUG_NO_HIT
            vec3 test = radiance(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz));
            if(dot(test, test) > 0.0) color += vec3(1.0); else color += vec3(0.5, 0.0, 0.1);
            #else
            color += radiance(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz));
            #endif
        }
        color /= float(npaths);
    }

	fragColor = vec4(pow(clamp(color, 0., 1.), vec3(1./2.2)), 1.);
}
