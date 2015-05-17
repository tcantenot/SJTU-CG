#include "params.glsl"
#include "ray.glsl"
#include "scene.glsl"

bool isolinesDebug(
    inout vec3 color,
    Ray ray,
    float rayLength,
    float y,
    Params params
)
{
    vec3 isolines = vec3(0.0);

    vec3 ro = ray.origin;
    vec3 rd = ray.direction;

    //FIXME
    y = 0.0;

    // If the ray is going towards the isolines plane
    if(rd.y * sign(ro.y - y) < 0.0)
    {
        float d = (ro.y - y) / -rd.y;
        if(d < rayLength)
        {
            vec3 hit = ro + d * rd;
            float hitDist = map(hit);
            float iso = fract(hitDist);// * 10.0);

            vec3 lhs = vec3(.2,.4,.6);
            vec3 rhs = vec3(.2,.2,.4);
            /*isolines = mix(lhs, rhs, clamp(hitDist/100.0, 0.0, 1.0));*/
            isolines = mix(lhs, rhs, iso);

            float dd = distance(ro, hit);


            #if 1
            if(mod(fract(hitDist * 10.0), 1.0) < 0.05)
            {
                float md = 15.0;
                if(dd < md)
                {
                    float m = smoothstep(dd/md, 0.0, 1.0);
                    m = 1.0 - m*m;
                    isolines = mix(color, vec3(0.8), m);
                }
            }
            #endif

            #if 1
            if(mod(fract(hitDist * 5.0), 1.0) < 0.05)
            {
                float md = 35.0;
                if(dd < md)
                {
                    float m = smoothstep(dd/md, 0.0, 1.0);
                    m = 1.0 - m*m;
                    isolines = mix(color, vec3(0.8), m);
                }
            }
            #endif

            #if 1
            float f = abs(ro.y - y);
            /*f = 1.0 / f;*/
            /*f = 1.0;*/
            float mm = clamp(dd, 0.0, 1.0);
            mm = 1.0 - mm;
            /*float m = 1.0;*/

            /*f *= 0.2;*/
            /*f = 1.0;*/

            float lw = 0.02 / (f*f);
            lw = clamp(lw, 0.03, 0.10);

            float rep = f;
            rep = clamp(rep, 1.0, 3.0);

            if(mod(fract(hitDist), rep) < lw)// < 0.005 * f)
            {
                if(hitDist > lw + 0.1)
                {
                    isolines = vec3(0.15);
                    isolines = vec3(0.0);

                    if(dd > 10.0)
                    {
                        /*isolines = mix(color, isolines, dd/10.0);*/
                    }
                }
            }
            #endif

            isolines *= 1.0 / max(0.0001, hitDist);
            /*isolines *= 0.25;*/

            vec2 uv = params.fragCoord / params.resolution;
            float m = 1.0;
            color = mix(vec3(uv, 1.0), isolines, m);

            return true;
        }
    }

    return false;
}
