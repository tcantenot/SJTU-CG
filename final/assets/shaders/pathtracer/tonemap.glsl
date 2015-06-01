
vec3 tonemap()
    fragColor = vec4(pow(clamp(color, 0.0, 1.0), vec3(1.0/2.2)), 1.0);
