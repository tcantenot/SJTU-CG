#include "ray.glsl"
#include "scene.glsl"

bool isolinesDebug(Ray ray, float rayLength, float y, out vec3 isolines)
{
    isolines = vec3(0.0);

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
            float iso = fract(hitDist * 10.0);

            vec3 lhs = vec3(.2,.4,.6);
            vec3 rhs = vec3(.2,.2,.4);
            /*lhs = vec3(.5, 0.0, 0.0);*/
            /*rhs = vec3(1.0, 0.0, 0.0);*/
            isolines = mix(lhs, rhs, iso);

            #if 1
            if(mod(fract(hitDist), 0.05) < 0.01)
            {
                isolines = vec3(0.15);
            }
            #endif

            #if 0
            if(mod(fract(hitDist), 0.02) < 0.004)
            {
                isolines = vec3(1.0);
            }
            #endif

            isolines *= 1.0 / max(0.0001, hitDist);
            isolines *= 0.10;

            return true;
        }
    }

    return false;
}
