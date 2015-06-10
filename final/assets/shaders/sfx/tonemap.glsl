////////////////////////////////////////////////////////////////////////////////
///                           GAMMA CORRECTION                               ///
////////////////////////////////////////////////////////////////////////////////

void gammaCorrection(inout vec3 color)
{
    color = pow(color, vec3(1.0/2.2));
}


////////////////////////////////////////////////////////////////////////////////
///                          UNCHARTED 2 TONEMAP                             ///
////////////////////////////////////////////////////////////////////////////////

float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
float W = 11.2;

vec3 _Uncharted2Tonemap(vec3 x)
{
   return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 Uncharted2Tonemap(vec3 color, float exposureBias)
{
   vec3 curr = _Uncharted2Tonemap(exposureBias * color);

   vec3 whiteScale = 1.0 / _Uncharted2Tonemap(vec3(W));
   color = curr * whiteScale;

   color = pow(color, vec3(1.0 / 2.2));

   return color;
}

vec3 Uncharted2Tonemap(vec3 color)
{
   const float ExposureBias = 10.0;
   return Uncharted2Tonemap(color, ExposureBias);
}
