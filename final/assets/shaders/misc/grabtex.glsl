

    vec2 dim = iChannelResolution[0].xy;
    if(fragCoord.x < dim.x && fragCoord.y < dim.y)
    {
        vec2 uv  = fragCoord / dim.xy;
        uv.y = 1.0 - uv.y;
        vec4 tex = texture2D(iChannel0, uv);
        fragColor = tex;
    }
    else
    {
        fragColor = vec4(vec3(0.0), 1.0);
    }
