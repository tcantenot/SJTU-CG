
float RANDOM_1F();
vec2 RANDOM_2F();

// See TotalCompendium
vec3 DISK_POINT(vec3 normal);
vec3 COSINE_DIRECTION(vec3 normal);
vec3 CONE_DIRECTION(vec3 normal, float angle);

float WORLD_SHADOW(vec3 pos, vec3 light);
vec2 WORLD_INTERSECT(vec3 ro, vec3 rd, float tmax);
vec3 WORLD_GET_BACKGROUND(vec3 rd);
vec3 WORLD_GET_NORMAL(vec3 pos, float id);
vec3 WORLD_GET_COLOR(vec3 pos, vec3 normal, float id);

void WORLD_MOVE_OBJECTS(float time);
mat4x3 WORLD_MOVE_CAMERA(float time);

uniform vec3 uSunDirection;
uniform vec3 uSunColor;
uniform vec3 uSkyColor;


vec3 WORLD_APPLYING_LIGHTING(vec3 pos, vec3 normal)
{
    vec3 dcol = vec3(0.0);

    // Sample sun
    {
        vec3  point = 1000.0 * uSunDirection + 50.0 * DISK_POINT(normal);
        vec3  light = normalize(point - pos);
        float NoL =  max(0.0, dot(normal, light));
        dcol += NoL * uSunColor * WORLD_SHADOW(pos, light);
    }

    // Sample sky
    {
        vec3  point = 1000.0 * COSINE_DIRECTION(normal);
        vec3  light = normalize(point - pos);
        dcol += uSkyColor * WORLD_SHADOW(pos, light);
    }

    return dcol;
}

vec3 WORLD_GET_BRDF_RAY(in vec3 pos, in vec3 normal, in vec3 eye, in float materialID)
{
    if(RANDOM_1F() < 0.8)
    {
        return COSINE_DIRECTION(normal);
    }
    else
    {
        return CONE_DIRECTION(reflect(eye, normal), 0.9);
    }
}

vec3 RENDERER_CALCULATE_COLOR(vec3 ro, vec3 rd, int numLevels)
{
    vec3 tcol = vec3(0.0);
    vec3 fcol = vec3(1.0);

    // Create numLevels light paths iteratively
    for(int i = 0; i < numLevels; i++)
    {
        // Intersect scene
        vec2 tres = WORLD_INTERSECT(ro, rd, 1000.0);

        float t  = tres.x;
        float id = tres.y;

        // If nothing found, return background color or break
        if(id < 0.0)
        {
            if(i == 0) fcol = WORLD_GET_BACKGROUND(rd);
            else break;
        }

        // Get position and normal at the intersection point
        vec3 pos = ro + t * rd;
        vec3 normal = WORLD_GET_NORMAL(pos, id);

        // Get color for the surface
        vec3 scol = WORLD_GET_COLOR(pos, normal, id);

        // Compute direct lighting
        vec3 dcol = WORLD_APPLYING_LIGHTING(pos, normal);

        // Prepare ray for indirect lighting gathering
        ro = pos;
        rd = WORLD_GET_BRDF_RAY(pos, normal, rd, id);

        // surface * lighting
        fcol *= scol;
        tcol += fcol * dcol;
    }

    return tcol;
}

// compute the color of a pixel
vec3 CALC_PIXEL_COLOR(vec2 pixel, vec2 resolution, float frameTime)
{
    const float shutterAperture = 0.6;
    const float fov = 2.5;
    const float focusDistance = 1.3;
    const float blurAmount = 0.0015;
    const int   numLevels = 5;

    // 256 paths per pixel
    const int npaths = 256.0;
    vec3 color = vec3(0.0);
    for(int i = 0; i < npaths; i++)
    {
        // Screen coords with antialiasing
        vec2 p = (2.0 * (pixel + RANDOM_2F()) - resolution) / resolution.y;

        // Motion blur
        float ctime = frameTime + shutterAperture * (1.0 / 24.0) * RANDOM_1F();

        // Move objects
        WORLD_MOVE_OBJECTS(ctime);

        // Get camera position, and right/up/front axis
        vec3 (ro, uu, vv, ww) = WORLD_MOVE_CAMERA(ctime);

        // Create ray with depth of field
        vec3 er = normalize(vec3(p.xy, fov));
        vec3 rd = er.x * uu + er.y * vv + er.z * ww;

        vec3 go = blurAmount * vec3(2.0 * RANDOM_2F() - 1.0, 0.0);
        vec3 gd = normalize(er * focusDistance - go);
        ro += go.x * uu + go.y * vv;
        rd += gd.x * uu + gd.y * vv;

        rd = normalize(rd);

        // Accumulate path
        color += RENDERER_CALCULATE_COLOR(ro, rd, numLevels);
    }
    color = color / npaths;

    // Apply gamma correction
    color = pow(color, 0.45);

    return color;
}

void main()
{
    vec3 color = CALC_PIXEL_COLOR(gl_FragCoord.xy, uResolution, uTime);
    RenderTarget0 = vec4(color, 1.0);
}
