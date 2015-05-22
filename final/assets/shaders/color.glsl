vec3 rgb2yuv(vec3 rgb)
{
    return vec3(dot(rgb, vec3(0.25,  0.50, 0.25)),
                dot(rgb, vec3(0.00, -0.50, 0.50)),
                dot(rgb, vec3(0.50, -0.50, 0.00)));
}

vec3 yuv2rgb(vec3 yuv)
{
    return vec3(dot(yuv, vec3(1.0, -0.5,  1.5)),
                dot(yuv, vec3(1.0, -0.5, -0.5)),
                dot(yuv, vec3(1.0,  1.5, -0.5)));
}
