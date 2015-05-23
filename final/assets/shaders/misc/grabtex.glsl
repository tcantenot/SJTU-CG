
    #define TEX_NUM 0
    #define TEX iChannel0

    vec2 dim = iChannelResolution[TEX_NUM].xy;
    if(fragCoord.x < dim.x && fragCoord.y < dim.y)
    {
        vec2 uv  = fragCoord / dim.xy;
        uv.y = 1.0 - uv.y;
        vec4 tex = texture2D(TEX, uv);
        fragColor = tex;
    }
    else
    {
        fragColor = vec4(vec3(0.0), 1.0);
    }
