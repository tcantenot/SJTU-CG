#include "light.glsl"
#include "material.glsl"
#include "scene.glsl"

float softShadows(vec3 ro, vec3 rd, const float mint, const float tmax)
{
	float res = 1.0;
    float t = mint;
    for(int i = 0; i < 50; i++)
    {
		float h = map(ro + t * rd);
        float sharpness = 20.0;
        res = min(res, sharpness * h / t);
        t += clamp(h, 0.02, 0.05);
        if(h < 0.001 || t > tmax) break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 phong(vec3 pos, vec3 normal, vec3 view, Light light, Material mat)
{
    vec3 l = light.position.xyz;
    float amb = clamp(0.5 + 0.5 * normal.y, 0.0, 1.0);
    float dif = clamp(dot(l, normal), 0.0, 1.0);
    vec3 h = normalize(view + l);
    float spe = pow(clamp(dot(h, normal), 0.0, 1.0), mat.shininess);

    float occ = 1.0;
    #if LIGHTING_OCCLUSION
    occ = 0.5 + 0.5 * normal.y;
    #endif

    float shadow = 1.0;
    #if LIGHTING_SHADOWS
    shadow = softShadows(pos, l, 0.02, 2.5);
    #endif

    vec3 color = vec3(0.0);
    color += amb * mat.ambient * occ;
    vec3 diffCoeff = light.power * light.color * dif * occ * shadow;
    color += diffCoeff * mat.diffuse;
    color += diffCoeff * spe * mat.specular;

    return color;
}
