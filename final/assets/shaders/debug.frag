#version 140

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse = vec4(0.0);

out vec4 RenderTarget0;


#define SCENE 2
//   0 = centered bboxes
//   1 = centered decorated bboxes
//   2 = non-centered bboxes
//   3 = non-centered decorated

#define OVERLAP_SCENE 2
//   0 = coins
//   1 = pipes
//   2 = tori
//   To show nothing just comment out OVERLAP.

// Enable to test overlap (must be less than 0.5):
/*#define OVERLAP 0.1*/

// Enable to debug distance field:
#define DEBUG_MODE 1
//   0 = no debug
//   1 = show DF plane
//   2 = show all DF slices

// Enable experimental AO (I still need to work on it):
//#define TEST_AO

#define VIEW_DIST 0
//   0 = short distance
//   1 = middle
//   2 = far

#if VIEW_DIST == 0
	const int ray_steps = 160;
	const float dist_max = 20.0;
	const float fog_start = 25.0;
	const float fog_density = 0.05;
	const float cam_dist = 20.0;
	const float cam_tilt = -.2;
#elif VIEW_DIST == 1
	const int ray_steps = 80;
	const float dist_max = 20.0;
	const float fog_start = 25.0;
	const float fog_density = 0.05;
	const float cam_dist = 30.0;
	const float cam_tilt = -.4;
#else
	const int ray_steps = 80;
	const float dist_max = 200.0;
	const float fog_start = 100.0;
	const float fog_density = 0.02;
	const float cam_dist = 80.0;
	const float cam_tilt = -.4;
#endif
const float floor_plane = -5.0;

// Tile space:
const float tile_d = 2.0;
const float tile_ood = 1.0/tile_d;

mat3 tori_rot[2];

// P-----+-----Q
// |     |     |
// |  A--|--B  |
// |  |p |  |  |
// +-----+-----+
// |  |  |  |  |
// |  C--|--D  |
// |     |     |
// R-----+-----S
// Say we want to find DF(p) = a distance field for "p",
// and "p" is inside ABCD boundary, where A,B,C,D are our tile centers.
// We have to assume max/min height.
// We call "frame", a bounding area of everything outside PQRS (estimated using max/min height).
// Algorithm:
//   For "p" we evaluate DF for 4 tiles: A,B,C,D
//   (possibly with early-out optimization with rough distance estimation)
//   and we bound it additionally to distance to PQRS frame.

float dist2frame(vec3 p, float box_y)
{
#ifdef OVERLAP
    vec3 dp = vec3(
        tile_d*(1.0-OVERLAP)-abs(p.x),
        max(0.0,abs(p.y)-box_y),
        tile_d*(1.0-OVERLAP)-abs(p.z));
#else
    vec3 dp = vec3(
        tile_d-abs(p.x),
        max(0.0,abs(p.y)-box_y),
        tile_d-abs(p.z));
#endif
    return length(vec2(min(dp.x,dp.z),dp.y));
}

float dist2box(vec3 p, float box_x, float box_y, float box_z, float box_r)
{
    // Distance to rounded box:
    vec3 dp = vec3(
        max(0.0,abs(p.x)-box_x),
        max(0.0,abs(p.y)-box_y),
        max(0.0,abs(p.z)-box_z));
    return length(dp) - box_r;
}

float dist2pipe(vec3 p, float r, float h, float cap)
{
    float dxz = length(p.xz) - r;
    float dy = max(0.0, abs(p.y) - h);
    return length(vec2(dxz,dy)) - cap;
}

float dist2cyl(vec3 p, float r, float h, float cap)
{
    float dxz = max(0.0, length(p.xz) - r);
    float dy = max(0.0, abs(p.y) - h);
    return length(vec2(dxz,dy)) - cap;
}

float evaluate_tile(vec3 p, vec3 p_id, float dx, float dy)
{
    p_id.xz += vec2(dx,dy);
    p.xz -= vec2(dx-.5,dy-.5)*tile_d;
    float anim = uTime*.25;

    anim = 48.0;

    float p1, dist;
    p1 = sin(p_id.x+anim)*sin(p_id.z+anim*.33);
#ifdef OVERLAP
    float r = tile_d*(.5 + OVERLAP);
    #if OVERLAP_SCENE == 0
    	dist = dist2cyl(vec3(p.x,p.y-p1*.25,p.z),r-.25,.0,.25);
    #elif OVERLAP_SCENE == 1
    	dist = dist2pipe(vec3(p.x,p.y-p1*2.0,p.z),r-.25,1.75,.25);
    #else
    	mat3 rot = (mod(p_id.x*.17 + p_id.z*.71,2.0)<1.0) ? tori_rot[0] : tori_rot[1];
        dist = dist2pipe(vec3(p.x,p.y-p1*3.0,p.z)*rot,r-.25,.0,.25);
    #endif
#else
    dist = 1e32;
#endif
#if SCENE >= 2
    p1 = 4.0 - abs(p1)*3.9;
    float id = p_id.x + p_id.z;
    vec3 p2 = p + vec3(cos(id*3.0+anim*1.11),0,sin(id*3.0+anim*1.11))*.5;
    dist = min(dist, dist2box(p2, .25, p1, .25, 0.025));
    #if SCENE == 3
    	//if (dist > .3) return dist - .1; // simple early-out optimziation
    	dist = min(dist, dist2box(p2 - vec3(0,p1*.333,0), .25, .0, .25, .1));
        dist = min(dist, dist2box(p2 - vec3(0,p1*.666,0), .25, .0, .25, .1));
    #endif
#else
    p1 = 4.0 - abs(p1)*3.8;
    float p2 = 0.2 + abs(cos(p_id.x+anim*.5)*cos(p_id.z+anim*.66))*.7;
    dist = min(dist, dist2box(p, p2, p1, p2, 0.025));
    #if SCENE == 1
        //if (dist > .2) return dist - .1; // simple early-out optimziation
        dist = min(dist, dist2box(p, p2+.1, p1-.1, .1, 0.025));
        dist = min(dist, dist2box(p, .1, p1-.1, p2+.1, 0.025));
    #endif
#endif
    return dist;
}

float get_distance(vec3 p)
{
    vec3 p_id = vec3(
        floor(p.x*tile_ood),
        0,
        floor(p.z*tile_ood));

    p = vec3(
        (fract(p.x*tile_ood)-.5)*tile_d,
        p.y, //(fract(p.y*tile_ood)-.5)*tile_d,
        (fract(p.z*tile_ood)-.5)*tile_d);

    float dist = dist2frame(p, 4.25);
    dist = min(dist, evaluate_tile(p, p_id, 0.0, 0.0));
    dist = min(dist, evaluate_tile(p, p_id, 1.0, 0.0));
    dist = min(dist, evaluate_tile(p, p_id, 0.0, 1.0));
    dist = min(dist, evaluate_tile(p, p_id, 1.0, 1.0));

    dist = min(dist, abs(p.y - floor_plane));
    return dist;
}

vec3 get_normal(vec3 p)
{
    const float eps = 1e-3;
    const vec3 x_eps = vec3(eps,0,0);
    const vec3 y_eps = vec3(0,eps,0);
    const vec3 z_eps = vec3(0,0,eps);
    return normalize(vec3(
        get_distance(p + x_eps) - get_distance(p - x_eps),
        get_distance(p + y_eps) - get_distance(p - y_eps),
        get_distance(p + z_eps) - get_distance(p - z_eps) ));
}

float get_ao(vec3 hit, vec3 n)
{
#ifdef TEST_AO
    // TODO: this AO sux, so would be nice to implement better approximation ;)
    const float ao_step = .1;
    float ao_dist, ao_len, d;
    hit += n*ao_step;
    ao_dist = get_distance(hit); d = ao_dist*ao_dist; ao_len = d;
    hit += n*ao_dist;
    ao_dist = get_distance(hit); d = ao_dist*ao_dist; ao_len += d;
    hit += n*ao_dist;
    ao_dist = get_distance(hit); d = ao_dist*ao_dist; ao_len += d;
    hit += n*ao_dist;
    ao_dist = get_distance(hit); d = ao_dist*ao_dist; ao_len += d;
    return clamp(0.0,1.0,ao_len*1.5);
#else
    return 1.0; // no AO for now looks better :(
#endif
}

vec3 trace(vec3 p_start, vec3 n)
{
#if DEBUG_MODE != 2
    float ray_len;
    float dist;
    const float dist_eps = .001;
    vec3 p = p_start;
    for(int k=0; k<ray_steps; ++k) {
    	dist = get_distance(p);
        if (dist < dist_eps || dist > dist_max) break;
        p += dist*n;
        ray_len += dist;
    }

    //vec3 light_dir = normalize(vec3(.1,1.0,-.3));
    float light_ang = (uMouse.x/uResolution.x-.5) + 1.0;
    vec3 light_dir = normalize(vec3(cos(light_ang),2.0,-sin(light_ang)));
    vec3 normal = get_normal(p);
    float shade = 0.0;
    float specular = 0.0;
    vec3 base_color = vec3(1.0,1.0,1.0);
    if (dist < dist_eps) {
        if (p.y < floor_plane + dist_eps*2.0) {
            float d = (p_start.y - floor_plane) / -n.y;
        	vec3 hit = p_start + n*d;
            float pattern = mod(floor(hit.x/tile_d)+floor(hit.z/tile_d),2.0);
            base_color = mix(vec3(.2,.4,.6),vec3(.4,.6,.8),pattern);
        }
        //shade = (1.0 - dist/dist_eps)*dot(normal, light_dir);
        shade = dot(normal, light_dir);
        shade = max(0.0, shade);
        shade *= get_ao(p,normal);
        specular = max(0.0,dot(n, light_dir - normal*dot(normal,light_dir)*2.0));
        specular = pow(specular,32.0)*.25;
    }

    vec3 color = mix(vec3(0.,.1,.3),vec3(1.,1.,.9),shade)*base_color;
    color += vec3(1.,1.,1.)*specular;

    // Test ray with cut_plane:
#if DEBUG_MODE == 1 && 1

    float cut_plane = (uMouse.y / uResolution.y - 0.1) * 8.0;

    cut_plane = max(0.0, cut_plane);
    if(n.y * sign(p_start.y - cut_plane) < 0.0)
    {
        float d = (p_start.y - cut_plane) / -n.y;
        if(d < ray_len)
        {
            vec3 hit = p_start + n*d;
            float hit_dist = get_distance(hit);
            float iso = fract(hit_dist*5.0);

            vec3 dist_color = mix(vec3(.2,.4,.6), vec3(.2,.2,.4), iso);

            dist_color *= 1.0 / (max(0.0, hit_dist) + 0.001);
            /*dist_color = min(vec3(1.0,1.0,1.0),dist_color);*/
            color = mix(color,dist_color, 0.25);
            /*color = dist_color;*/
            ray_len = d;
        }
    }

#endif
    vec3 fog_color = vec3(.8,.8,.8);
    float fog = 1.0-1.0/exp(max(0.0,ray_len-fog_start)*fog_density);
    /*color = mix(color,fog_color,fog);*/
#else
    vec3 color = vec3(0.,.1,.3);

    for(float cut_plane = 4.0; cut_plane >= 0.0; cut_plane -= 0.1) {
        // Test ray with cut_plane:
        if (n.y*sign(p_start.y-cut_plane) < 0.0) {
            float d = (p_start.y - cut_plane) / -n.y;
            vec3 hit = p_start + n*d;
            float hit_dist = get_distance(hit);
            float iso = fract(hit_dist*5.0);
            vec3 dist_color = mix(vec3(.2,.4,.6),vec3(.2,.2,.4),iso);
            dist_color *= 1.0/(max(0.0,hit_dist)+.05);
            color += dist_color*.02*cut_plane*.25;
        }
    }
#endif

	return color;
}

mat3 from_axis_angle(float angle, vec3 axis) {
  	float si, co, ti, tx, ty, tz, sx, sy, sz;

    si = sin(angle);
    co = cos(angle);
    ti = 1.0 - co;

    tx = ti * axis.x; ty = ti * axis.y; tz = ti * axis.z;
    sx = si * axis.x; sy = si * axis.y; sz = si * axis.z;

    return mat3(
        tx * axis.x + co, tx * axis.y + sz, tx * axis.z - sy,
        tx * axis.y - sz, ty * axis.y + co, ty * axis.z + sx,
        tx * axis.z + sy, ty * axis.z - sx, tz * axis.z + co
    );
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord.xy - uResolution.xy*0.5) / uResolution.x;

    float anim = uTime*.25;
    anim = 48.0;

    float a = -0.2; //uMouse.x / uResolution.x * 2.0 - 1.0;
    a += cos(anim)*.05;
    float co = cos(a);
    float si = sin(a);
    vec3 p1 = vec3(-cam_dist*si, 0, -cam_dist*co);
    vec3 n1 = normalize(vec3(uv,1));
    vec3 n2 = vec3(n1.x*co + n1.z*si, n1.y, -n1.x*si + n1.z*co);

    //a = uMouse.y / uResolution.y * 2.0 + sin(anim*(2.0/3.0))*.2 - 2.0;
    a = cam_tilt;
    co = cos(a);
    si = sin(a);
    vec3 p2 = vec3(p1.x, p1.y*co + p1.z*si, -p1.y*si + p1.z*co);
    vec3 n3 = vec3(n2.x, n2.y*co + n2.z*si, -n2.y*si + n2.z*co);

#if defined(OVERLAP) && OVERLAP_SCENE == 2
    tori_rot[0] = from_axis_angle(anim, normalize(vec3(.5,.2,.3)));
	tori_rot[1] = from_axis_angle(anim+2.0, normalize(vec3(.3,.7,-.2)));
#endif

    RenderTarget0 = vec4(trace(p2, n3), 1.0);
}
