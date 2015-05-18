#include "params.glsl"
#include "ray.glsl"
#include "scene.glsl"

bool isolinesDebug(
    inout vec3 color,
    Ray ray,
    float rayLength,
    float y,
    Params params,
    float mixCoeff,
    float falloff
)
{
    vec3 isolines = vec3(0.0);

    vec3 ro = ray.origin;
    vec3 rd = ray.direction;

    // If the ray is going towards the isolines plane
    if(rd.y * sign(ro.y - y) < 0.0)
    {
        float d = (ro.y - y) / -rd.y;
        if(d < rayLength)
        {
            vec3 hit = ro + d * rd;
            float hitDist = map(hit);
            float iso = fract(hitDist);

            vec3 lhs = vec3(.2,.4,.6);
            vec3 rhs = vec3(.2,.2,.4);
            /*isolines = mix(lhs, rhs, clamp(hitDist/1.0, 0.0, 1.0));*/
            isolines = mix(lhs, rhs, iso);

            float dd = distance(ro, hit);

            // Line width
            float lw;


            // Every 1/10
            #if 1
            lw = 0.005;
            if(hitDist > lw && mod(hitDist, 0.1) < lw)
            {
                float md = 10.0;
                if(dd < md)
                {
                    float m = smoothstep(0.0, 1.0, dd/md);
                    m = 1.0 - m*m;
                    isolines = mix(color, vec3(0.8), m);
                }
            }
            #endif

            // Every 1/5
            #if 1
            lw = 0.01;
            if(hitDist > lw && mod(hitDist, 0.2) < lw)
            {
                float md = 25.0;
                if(dd < md)
                {
                    float m = smoothstep(0.0, 1.0, dd/md);
                    m = 1.0 - m*m;
                    isolines = mix(color, vec3(0.8), m);
                }
            }
            #endif

            // Every 1
            #if 1
            lw = 0.03;
            if(hitDist > lw && mod(hitDist, 1.0) < lw)
            {
                isolines = vec3(0.0);
            }
            #endif

            isolines *= 1.0 / max(0.001, falloff * hitDist);

            color = mix(color, isolines, mixCoeff);

            return true;
        }
    }

    return false;
}

bool isolinesDebug(inout vec3 color, Ray ray, float rayLength, float y, Params params)
{
    return isolinesDebug(color, ray, rayLength, y, params, 1.0, 1.2);
}
