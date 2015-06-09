void gammaCorrection(inout vec3 color)
{
    color = pow(color, vec3(1.0/2.2));
}
