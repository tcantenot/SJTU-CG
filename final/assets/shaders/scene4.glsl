#include "hitinfo.glsl"
#include "operators.glsl"
#include "primitives.glsl"

float MengerSponge(vec3 p, inout HitInfo hitInfo)
{
    float d = sdBox(p,vec3(1.0));
    vec3 res = vec3(d, 1.0, 0.0);

    float s = 1.0;
    for(int m = 0 ; m < 3; m++)
    {
        vec3 a = mod(p * s, 2.0) - 1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0 * abs(a));

        float da = max(r.x,r.y);
        float db = max(r.y,r.z);
        float dc = max(r.z,r.x);
        float c = (min(da, min(db, dc)) - 1.0) / s;

        if(c > d)
        {
            d = c;
            res = vec3(d, 0.2 * da * db * dc, (1.0 + float(m)) / 4.0);
        }
    }

    hitInfo.id = 1;

    return res.x;
}

float mengerSponge(vec3 p, inout HitInfo hitInfo)
{
    float x = p.x;
    float y = p.y;
    float z = p.z;

    float res = 0.0;
    if(x<0 || x>1 || y<0 || y>1 || z<0 || z>1 )
    {
        hitInfo.id = -1;
        return res;
    } 		// point is not part of menger sponge

    int iterations=8;

    float depth=3;

    for(int iter=0; iter<iterations; iter++) {
        int holex=1;
        while(holex<depth) {
            int holey=1;
            while(holey<depth) {
                if(
                        ((x > holex/depth && x< (holex+1) /depth) && (y > holey/depth && y< (holey+1) /depth)) ||
                        ((y > holex/depth && y< (holex+1) /depth) && (z > holey/depth && z< (holey+1) /depth)) ||
                        ((x > holex/depth && x< (holex+1) /depth) && (z > holey/depth && z< (holey+1) /depth))
                  )
                  {
                      hitInfo.id = -1;
                      return res;
                }		// point is not part of menger sponge
                holey+=3;
            }
            holex+=3;
        }
        depth*=3;
    }

    hitInfo.id = 1;
    return res;
}

#define HOOK_MAP MengerSponge
