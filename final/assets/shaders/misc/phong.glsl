vec3 ambientColor = vec3(0.05, 0.15, 0.2);
vec3 diffuseColor = vec3(0.2, 0.6, 0.8);
vec3 specularColor = vec3(1.0, 1.0, 1.0);
vec3 lightDir = normalize(vec3(0.0, 4.0, 5.0));
vec3 spherePos = vec3(0.0, 0.5, 0.0);

float raytraceSphere(in vec3 ro, in vec3 rd, float tmin, float tmax, float r) {
    vec3 ce = ro - spherePos;
    float b = dot(rd, ce);
    float c = dot(ce, ce) - r * r;
    float t = b * b - c;
    if (t > tmin) {
        t = -b - sqrt(t);
        if (t < tmax)
            return t;
        }
    return -1.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = (-iResolution.xy + 2.0 * fragCoord.xy) / iResolution.y;
    vec3 eye = vec3(0.0, 1.0, 2.0);
    vec2 rot = 6.2831 * (vec2(0.1 + iGlobalTime * 0.25, 0.0) + vec2(1.0, 0.0) * (iMouse.xy - iResolution.xy * 0.25) / iResolution.x);
    eye.yz = cos(rot.y) * eye.yz + sin(rot.y) * eye.zy * vec2(-1.0, 1.0);
    eye.xz = cos(rot.x) * eye.xz + sin(rot.x) * eye.zx * vec2(1.0, -1.0);

    vec3 ro = eye;
    vec3 ta = vec3(0.0, 0.5, 0.0);

    vec3 cw = normalize(ta - eye);
    vec3 cu = normalize(cross(vec3(0.0, 1.0, 0.0), cw));
    vec3 cv = normalize(cross(cw, cu));
    mat3 cam = mat3(cu, cv, cw);

    vec3 rd = cam * normalize(vec3(p.xy, 1.5));

    vec3 color;

    float tmin = 0.1;
    float tmax = 50.0;
    float t = raytraceSphere(ro, rd, tmin, tmax, 1.0);
    if (t > tmin && t < tmax) {
        vec3 pos = ro + rd * t;
        vec3 norm = normalize(pos - spherePos);
        float occ = 1.0;//0.5 + 0.5 * norm.y;

        float amb = clamp(0.5 + 0.5 * norm.y, 0.0, 1.0);
        float dif = clamp(dot(lightDir, norm), 0.0, 1.0);

        vec3 h = normalize(-rd + lightDir);
        float spe = pow(clamp(dot(h, norm), 0.0, 1.0), 64.0);

        color = amb * ambientColor * occ;
        color += dif * diffuseColor * occ;
        color += dif * spe * specularColor * occ;
    }

    vec3 gamma = vec3(1.0 / 2.2);
    fragColor = vec4(pow(color, gamma), 1.0);
}
