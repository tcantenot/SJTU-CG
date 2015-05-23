/*

This shader is an attempt at porting smallpt to GLSL.

See what it's all about here:
http://www.kevinbeason.com/smallpt/

The code is based in particular on the slides by David Cline.

Some differences:

- For optimization purposes, the code considers there is
  only one light source(see the commented loop)
- Russian roulette and tent filter are not implemented

I spent quite some time pulling my hair over inconsistent
behavior between Chrome and Firefox, Angle and native. I
expect many GLSL related bugs to be lurking, on top of
implementation errors. Please Let me know if you find any.

--
Zavie

*/

// Play with the two following values to change quality.
// You want as many samples as your GPU can bear. :)
#define SAMPLES 64
#define MAXDEPTH 4

// Uncomment to see how many samples never reach a light source
/*#define DEBUG*/

#define DEPTH_RUSSIAN 2
#define RUSSIAN_ROULETTE 0

#define PI 3.14159265359
#define DIFF 0
#define SPEC 1
#define REFR 2
#define NUM_SPHERES 9

float seed = 0.;
float rand()
{
    return fract(sin(seed++)*43758.5453123);
}

struct Light
{
    vec3 pos;
    float radius;
    vec3 color;
    float power;
};

const int LIGHT_COUNT = 2;
Light uLights[LIGHT_COUNT] = Light[](
    Light(vec3(50.0, 81.6, 81.6), 20.0, vec3(1.0), 3.0),
    Light(vec3(75.0, 22., 30.6), 10.0, vec3(0.8, 0.5, 0.3), 17.0)
);


struct Ray { vec3 o, d; };
struct Sphere
{
	float radius;
	vec3 pos;
    vec3 emissive;
    vec3 color;
	int refl;
};

Sphere lightSourceVolume = Sphere(20., vec3(50., 81.6, 81.6), vec3(12.), vec3(0.), DIFF);
Sphere spheres[NUM_SPHERES];
void initSpheres() {
    // Red wall
	spheres[0] = Sphere(1e5, vec3(-1e5+1., 40.8, 81.6),	vec3(0.),  vec3(.75, .25, .25), DIFF);

    // Blue wall
	spheres[1] = Sphere(1e5, vec3( 1e5+99., 40.8, 81.6),vec3(0.),  vec3(.25, .25, .75), DIFF);


    // Front wall
	spheres[2] = Sphere(1e5, vec3(50., 40.8, -1e5),		vec3(0.),  vec3(.75), DIFF);

    // Back wall
	spheres[3] = Sphere(1e5, vec3(50., 40.8,  1e5+170),vec3(0.25, 0.75, 0.25),  vec3(0.), DIFF);

    // Floor
	spheres[4] = Sphere(1e5, vec3(50., -1e5, 81.6),		vec3(0.),  vec3(.75), DIFF);

    // Ceiling
	spheres[5] = Sphere(1e5, vec3(50.,  1e5+81.6, 81.6),vec3(0.),  vec3(.75), DIFF);

    // Metallic ball
	spheres[6] = Sphere(16.5, vec3(27., 16.5, 47.), 	vec3(0.),  vec3(1.), SPEC);

    // Glass ball
	spheres[7] = Sphere(16.5, vec3(73., 16.5, 78.), 	vec3(0.),  vec3(.7, 1., .9), REFR);

    // Ceiling light
	/*spheres[8] = Sphere(uLight.radius/10.0, uLight.pos,	uLight.color, uLight.color, DIFF);*/
	spheres[8] = Sphere(600., vec3(50., 681.33, 81.6),	vec3(1.), vec3(0.), DIFF);
}

float intersect(Sphere s, Ray ray) {
	vec3 op = s.pos - ray.o;
	float t, epsilon = 1e-3, b = dot(op, ray.d), det = b * b - dot(op, op) + s.radius * s.radius;
	if(det < 0.) return 0.; else det = sqrt(det);
	return(t = b - det) > epsilon ? t :((t = b + det) > epsilon ? t : 0.);
}

int intersect(Ray ray, out float t, out Sphere s, int avoid) {
	int id = -1;
	t = 1e5;
	s = spheres[0];
	for(int i = 0; i < NUM_SPHERES; ++i) {
        if(i == avoid) continue;
		Sphere S = spheres[i];
		float d = intersect(S, ray);
		if(d!=0. && d<t) { t = d; id = i; s=S; }
	}
	return id;
}

float intersect(Light s, Ray ray) {
	vec3 op = s.pos - ray.o;
	float t, epsilon = 1e-3, b = dot(op, ray.d), det = b * b - dot(op, op) + s.radius * s.radius;
	if(det < 0.) return 0.; else det = sqrt(det);
	return(t = b - det) > epsilon ? t :((t = b + det) > epsilon ? t : 0.);
}

vec3 jitter(vec3 d, float phi, float sina, float cosa)
{
	vec3 w = normalize(d);
    vec3 u = normalize(cross(w.yzx, w));
    vec3 v = cross(w, u);
	return (u * cos(phi) + v * sin(phi)) * sina + w * cosa;
}

vec3 radiance(Ray ray)
{
	vec3 acc = vec3(0.);
	vec3 mask = vec3(1.);
	int id = -1;

	for(int depth = 0; depth < MAXDEPTH; ++depth)
    {
		float t;
		Sphere obj;

        // If no hit, exit
		if((id = intersect(ray, t, obj, id)) < 0) break;

		vec3 hit = t * ray.d + ray.o;
		vec3 n = normalize(hit - obj.pos);
        vec3 normal = n * sign(-dot(n, ray.d));

        #if RUSSIAN_ROULETTE
        {
            vec3 f = obj.color;
            float E = 1.0;
            float pr = dot(f, vec3(1.2126, 0.7152, 0.0722));
            if(depth > DEPTH_RUSSIAN || pr == 0.)
            {
                if(rand() < pr) f /= pr;
                else { acc += mask * obj.emissive * E; break; }
            }
        }
        #endif

        // Diffuse material
		if(obj.refl == DIFF)
        {
            // Check if current object is visible to any emissive objects
			vec3 emissive = vec3(0.);
            #if 0
            for(int i = 0; i < NUM_SPHERES; ++i)
			{
                Sphere s = spheres[i];
                if(dot(s.emissive, vec3(1.)) == 0.) continue;

				// Normally we would loop over the light sources and
				// cast rays toward them, but since there is only one
				// light source, that is mostly occluded, here goes
				// the ad hoc optimization:
                /*Sphere s = lightSourceVolume;*/
                /*int i = 8;*/

				vec3 lightDir = s.pos - hit;

				float cos_a_max = sqrt(1. - clamp(s.radius * s.radius / dot(lightDir, lightDir), 0., 1.));
				float cosa = mix(cos_a_max, 1., rand());

                // Light direction: random vector on the "light direction"-oriented hemisphere
				vec3 l = jitter(lightDir, 2.*PI*rand(), sqrt(1. - cosa*cosa), cosa);

                // If a light is hit
				if(intersect(Ray(hit, l), t, s, id) == i)
                {
					float omega = 2. * PI *(1. - cos_a_max);
					emissive +=(s.emissive * clamp(dot(l, n),0.,1.) * omega) / PI;
				}
			}
            #endif

            for(int i = 0; i < LIGHT_COUNT; ++i)
            {
                Light light = uLights[i];

                // Vector hit-light
                vec3 lightDir = light.pos - hit;

                // Cosine of the maximum angle to reach the light (cone of light rays)
				float cos_a_max = sqrt(1. - clamp(light.radius * light.radius / dot(lightDir, lightDir), 0., 1.));

                // Random cosine inside the cone of light
				float cosa = mix(cos_a_max, 1., rand());

                // Light direction: random vector in the cone of light
				vec3 l = jitter(lightDir, 2.*PI*rand(), sqrt(1. - cosa*cosa), cosa);

                // Check if the current hit point if visible from the light
                Sphere _;
                intersect(Ray(hit, l), t, _, id);
                float lightDist = intersect(light, Ray(hit, l));
				if(lightDist < t)
                {
                    float dist = length(lightDir);
                    /*float atten = 1.0 / (dist * dist);*/
                    /*float power = 2000.0;*/
                    /*emissive += power * atten * light.color * clamp(dot(lightDir, normal), 0.0, 1.0);*/

                    float omega = 2. * PI * (1. - cos_a_max);
                    emissive += (light.power * light.color * clamp(dot(lightDir, normal), 0.0, 1.0) * omega) / PI;
                }
            }


			float E = 1.;//float(depth==0);
			acc += mask * obj.emissive * E + mask * obj.color * emissive;
			mask *= obj.color;

            // New ray direction: random vector on the normal-oriented hemisphere
			float r2 = rand();
			vec3 d = jitter(normal, 2.*PI*rand(), sqrt(r2), sqrt(1. - r2));

			ray = Ray(hit, d);
		}

        // Specular (reflective) material
        else if(obj.refl == SPEC)
        {
			acc += mask * obj.emissive;
			mask *= obj.color;
			ray = Ray(hit, reflect(ray.d, n));
		}
        // Refractive material
        else
        {
			float a=dot(n,ray.d), ddn=abs(a);
			float nc=1., nt=1.5, nnt=mix(nc/nt, nt/nc, float(a>0.));
			float cos2t=1.-nnt*nnt*(1.-ddn*ddn);
			ray = Ray(hit, reflect(ray.d, n));
			if(cos2t>0.)
            {
				vec3 tdir = normalize(ray.d*nnt + sign(a)*n*(ddn*nnt+sqrt(cos2t)));
				float R0=(nt-nc)*(nt-nc)/((nt+nc)*(nt+nc)),
					hov = 1.-mix(ddn,dot(tdir, n),float(a>0.));
				float Re=R0+(1.-R0)*pow(hov,5.0),P=.25+.5*Re,RP=Re/P,TP=(1.-Re)/(1.-P);
				if(rand()<P) { mask *= RP; }
				else { mask *= obj.color*TP; ray = Ray(hit, tdir); }
			}
		}
	}

	return acc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord) {
	initSpheres();
    float time = uTime;
    time = 42.0;
	seed = time + uResolution.y * fragCoord.x / uResolution.x + fragCoord.y / uResolution.y;
	vec2 uv = 2. * fragCoord.xy / uResolution.xy - 1.;
	vec3 camPos = vec3((2. *(uMouse.xy==vec2(0.)?.5*uResolution.xy:uMouse.xy) / uResolution.xy - 1.) * vec2(48., 40.) + vec2(50., 40.8), 169.);
	vec3 cz = normalize(vec3(50., 40., 81.6) - camPos);
	vec3 cx = vec3(1., 0., 0.);
	vec3 cy = normalize(cross(cx, cz)); cx = cross(cz, cy);
	vec3 color = vec3(0.);

    vec2 pixel = fragCoord;
    vec2 resolution = uResolution;

    float npaths = SAMPLES;
    float aa = float(npaths) / 2.0;
    for(int i = 0; i < npaths; i++)
    {
        vec2 seed = vec2(float(i), float(i+1));

        vec2 offset = vec2(mod(float(i), aa), mod(float(i/2), aa)) / aa;

        // Screen coords with antialiasing
        vec2 p = (2.0 * (pixel + offset) - resolution) / resolution.y;

        #ifdef DEBUG
        vec3 test = radiance(Ray(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz)));
        if(dot(test, test) > 0.) color += vec3(1.); else color += vec3(0.5,0.,0.1);
        #else
        color += radiance(Ray(camPos, normalize(.53135 *(p.x * cx + p.y * cy) + cz)));
        #endif
    }
    color /= float(npaths);

	fragColor = vec4(pow(clamp(color, 0., 1.), vec3(1./2.2)), 1.);
}
