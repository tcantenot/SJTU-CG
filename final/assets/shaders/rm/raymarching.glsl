#include "core.glsl"

/*#ifdef HOOK_MAP*/
/*#define map(p, hitInfo) HOOK_MAP(p, hitInfo)*/
/*#else*/
/*float map(vec3 p, out HitInfo hitInfo)*/
/*{*/
    /*const float INF = 1e5;*/
    /*hitInfo.id = -1;*/
    /*return INF;*/
/*}*/
/*#endif*/

float map(vec3 p)
{
    HitInfo _;
    return map(p, _);
}

// Compute normal by central differences on the distance field at the shading point
// (gradient approximation)
vec3 calcNormal(vec3 pos)
{
    vec3 eps = vec3(0.001, 0.0, 0.0);
    vec3 normal = vec3(
        map(pos+eps.xyy) - map(pos-eps.xyy),
        map(pos+eps.yxy) - map(pos-eps.yxy),
        map(pos+eps.yyx) - map(pos-eps.yyx)
    );
    return normalize(normal);
}


bool raymarch(
    Ray ray,
    const float tmin, const float tmax,
    const float precis, const int stepmax,
    inout HitInfo hitInfo
)
{
    vec3 ro = ray.origin;
    vec3 rd = ray.direction;
    float t = tmin;

    hitInfo.id = -1;

    // Raymarching using "sphere" tracing
    for(int i = 0; i < stepmax; i++)
    {
        float d = map(ro + t * rd, hitInfo);
        t += abs(d);
        if(abs(d) < precis || t > tmax) break;

        /*t += d;*/
        /*if(d < precis || t > tmax) break;*/
    }

    // No hit
    if(t > tmax)
    {
        hitInfo.id = -1;
        return false;
    }
    else
    {
        // Store hit info
        hitInfo.dist   = t;
        hitInfo.pos    = ro + t * rd;
        hitInfo.normal = calcNormal(hitInfo.pos);
        return true;
    }
}
