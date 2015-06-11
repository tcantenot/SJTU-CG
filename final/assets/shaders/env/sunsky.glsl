// Atmospheric scattering model
//
// IMPORTANT COPYRIGHT INFO:
// -----------------------------------
// The license of this fragment is not completely clear to me, but for all I
// can tell this shader derives from the MIT licensed source given below.
//
// This shader derives from:
// https://github.com/Syntopia/Fragmentarium/blob/master/Fragmentarium-Source/Examples/Include/Sunsky.frag
//
// Which in turn derived from this shader: http://glsl.herokuapp.com/e#9816.0
// written by Martijn Steinrucken: countfrolic@gmail.com
//
// Which in turn contained the following copyright info:
// Code adapted from Martins:
// http://blenderartists.org/forum/showthread.php?242940-unlimited-planar-reflections-amp-refraction-%28update%29
//
// Which in turn originates from:
// https://github.com/SimonWallner/kocmoc-demo/blob/RTVIS/media/shaders/sky.frag
// where it was MIT licensed:
// https://github.com/SimonWallner/kocmoc-demo/blob/RTVIS/README.rst


////////////////////////////////////////////////////////////////////////////////
///                            PUBLIC FUNCTIONS                              ///
////////////////////////////////////////////////////////////////////////////////

vec3  getSunDirection();
float getSunCosAngularDiameter();
vec3  sun(vec3 viewDir);
vec3  sky(vec3 viewDir);
vec3  sunsky(vec3 viewDir);


////////////////////////////////////////////////////////////////////////////////
///                             IMPLEMENTATION                               ///
////////////////////////////////////////////////////////////////////////////////

#include "sun.glsl"

#ifndef PI
#define PI 3.14159265359
#endif

// Retrieve the sun from hook function
Sun gSun = HookSun();

float _sunIntensity = gSun.intensity;


/*uniform vec2 _sunAngularPos = vec2(0.7, 0.12); //slider[(0,0),(0,0.2),(1,1)]*/
/*vec2 _sunAngularPos = vec2(2.0 * uTweaks.x, 2.0 * uTweaks.y);*/
/*vec2 _sunAngularPos = vec2(0.54, 0.12);*/
/*vec2 _sunAngularPos = vec2(1.70, 1.86);*/
// TODO: use degree
/*vec2 _sunAngularPos = vec2(sun.angularPosition * PI / 180.0);*/
vec2 _sunAngularPos = gSun.angularPosition;

// Angular sun size - physical sun is 0.53 degrees
float _sunAngularSize = gSun.angularSize;

float _sunCosAngularDiameter = cos(_sunAngularSize*PI/180.0);

vec3 _fromSpherical(vec2 p)
{
	return vec3(cos(p.x) * sin(p.y), sin(p.x) * sin(p.y), cos(p.y));
}

vec3 _sunDirection = normalize(_fromSpherical((_sunAngularPos-vec2(0.0,0.5))*vec2(6.28,3.14)));

vec3 getSunDirection()
{
    return _sunDirection;
}

float getSunCosAngularDiameter()
{
    return _sunCosAngularDiameter;
}

/*uniform float turbidity = 16.0; //slider[1,2,16]*/
/*float turbidity = 16.0 * uTweaks.z; //slider[1,2,16]*/
const float turbidity = 1.76;

/*uniform float SkyFactor = 1.0; //slider[0,1,100]*/
/*float SkyFactor = 2.0 * uTweaks.w; //slider[0,1,100]*/
const float SkyFactor = 1.0;



const float mieCoefficient = 0.005;
const float mieDirectionalG = 0.80;

// constants for atmospheric scattering
const float n = 1.0003; // refractive index of air
const float N = 2.545E25; // number of molecules per unit volume for air at
// 288.15K and 1013mb (sea level -45 celsius)

// wavelength of used primaries, according to preetham
const vec3 primaryWavelengths = vec3(680E-9, 550E-9, 450E-9);

// mie stuff
// K coefficient for the primaries
const vec3 K = vec3(0.686, 0.678, 0.666);
const float v = 4.0;

// optical length at zenith for molecules
const float rayleighZenithLength = 8.4E3;
const float mieZenithLength = 1.25E3;
const vec3 up = vec3(0.0, 1.0, 0.0);

float RayleighPhase(float cosViewSunAngle)
{
	return (3.0 / (16.0*PI)) * (1.0 + pow(cosViewSunAngle, 2.0));
}

vec3 totalMie(vec3 primaryWavelengths, vec3 K, float T)
{
	float c = (0.2 * T ) * 10E-18;
	return 0.434 * c * PI * pow((2.0 * PI) / primaryWavelengths, vec3(v - 2.0)) * K;
}

float hgPhase(float cosViewSunAngle, float g)
{
	return (1.0 / (4.0*PI)) * ((1.0 - pow(g, 2.0)) / pow(1.0 - 2.0*g*cosViewSunAngle + pow(g, 2.0), 1.5));
}

float SunIntensity(float zenithAngleCos)
{
    // Earth shadow hack
    const float cutoffAngle = PI/1.95;
    const float steepness = 1.5;

	return _sunIntensity;//*
        //max(0.0, 1.0 - exp(-((cutoffAngle - acos(zenithAngleCos)) / steepness)));
}

vec3 sun(vec3 viewDir)
{
	// Cos angles
	float cosViewSunAngle = dot(viewDir, _sunDirection);
	float cosSunUpAngle = dot(_sunDirection, up);
	float cosUpViewAngle = dot(up, viewDir);

	float sunE = SunIntensity(cosSunUpAngle);  // Get sun intensity based on how high in the sky it is
	// extinction (absorption + out scattering)
	// rayleigh coeficients
	vec3 rayleighAtX = vec3(5.176821E-6, 1.2785348E-5, 2.8530756E-5);

	// mie coefficients
	vec3 mieAtX = totalMie(primaryWavelengths, K, turbidity) * mieCoefficient;

	// optical length
	// cutoff angle at 90 to avoid singularity in next formula.
	float zenithAngle = max(0.0, cosUpViewAngle);

	float rayleighOpticalLength = rayleighZenithLength / zenithAngle;
	float mieOpticalLength = mieZenithLength / zenithAngle;


	// combined extinction factor
	vec3 Fex = exp(-(rayleighAtX * rayleighOpticalLength + mieAtX * mieOpticalLength));

	// in scattering
	vec3 rayleighXtoEye = rayleighAtX * RayleighPhase(cosViewSunAngle);
	vec3 mieXtoEye = mieAtX *  hgPhase(cosViewSunAngle, mieDirectionalG);

	vec3 totalLightAtX = rayleighAtX + mieAtX;
	vec3 lightFromXtoEye = rayleighXtoEye + mieXtoEye;

	vec3 somethingElse = sunE * (lightFromXtoEye / totalLightAtX);

	vec3 sky = somethingElse * (1.0 - Fex);
	sky *= mix(vec3(1.0),pow(somethingElse * Fex,vec3(0.5)),clamp(pow(1.0-dot(up, _sunDirection),5.0),0.0,1.0));
	// composition + solar disc

//	float sundisk = smoothstep(_sunCosAngularDiameter,_sunCosAngularDiameter+0.00002,cosViewSunAngle);
	float sundisk =
		_sunCosAngularDiameter < cosViewSunAngle ? 1.0 : 0.0;
	//	smoothstep(_sunCosAngularDiameter,_sunCosAngularDiameter+0.00002,cosViewSunAngle);
	vec3 sun = (sunE * 19000.0 * Fex)*sundisk;

	return 0.01*sun;
}

vec3 sky(vec3 viewDir)
{
	// Cos angles
	float cosViewSunAngle = dot(viewDir, _sunDirection);
	float cosSunUpAngle = dot(_sunDirection, up);
	float cosUpViewAngle = dot(up, viewDir);

	float sunE = SunIntensity(cosSunUpAngle);  // Get sun intensity based on how high in the sky it is
	// extinction (absorption + out scattering)
	// rayleigh coeficients
	vec3 rayleighAtX = vec3(5.176821E-6, 1.2785348E-5, 2.8530756E-5);

	// mie coefficients
	vec3 mieAtX = totalMie(primaryWavelengths, K, turbidity) * mieCoefficient;

	// optical length
	// cutoff angle at 90 to avoid singularity in next formula.
	float zenithAngle = max(0.0, cosUpViewAngle);

	float rayleighOpticalLength = rayleighZenithLength / zenithAngle;
	float mieOpticalLength = mieZenithLength / zenithAngle;


	// combined extinction factor
	vec3 Fex = exp(-(rayleighAtX * rayleighOpticalLength + mieAtX * mieOpticalLength));

	// in scattering
	vec3 rayleighXtoEye = rayleighAtX * RayleighPhase(cosViewSunAngle);
	vec3 mieXtoEye = mieAtX *  hgPhase(cosViewSunAngle, mieDirectionalG);

	vec3 totalLightAtX = rayleighAtX + mieAtX;
	vec3 lightFromXtoEye = rayleighXtoEye + mieXtoEye;

	vec3 somethingElse = sunE * (lightFromXtoEye / totalLightAtX);

	vec3 sky = somethingElse * (1.0 - Fex);
	sky *= mix(vec3(1.0),pow(somethingElse * Fex,vec3(0.5)),clamp(pow(1.0-dot(up, _sunDirection),5.0),0.0,1.0));
	// composition + solar disc

	return SkyFactor * 0.01 * sky;
}

vec3 sunsky(vec3 viewDir)
{
	// Cos angles
	float cosViewSunAngle = dot(viewDir, _sunDirection);
	float cosSunUpAngle = dot(_sunDirection, up);
	float cosUpViewAngle = dot(up, viewDir);

	if(_sunCosAngularDiameter == 1.0)
    {
	    return vec3(1.0, 0.0, 0.0);
    }

	float sunE = SunIntensity(cosSunUpAngle);  // Get sun intensity based on how high in the sky it is
	// Extinction (absorption + out scattering)
	// rayleigh coeficients
	vec3 rayleighAtX = vec3(5.176821E-6, 1.2785348E-5, 2.8530756E-5);

	// mie coefficients
	vec3 mieAtX = totalMie(primaryWavelengths, K, turbidity) * mieCoefficient;

	// optical length
	// cutoff angle at 90 to avoid singularity in next formula.
	float zenithAngle = max(0.0, cosUpViewAngle);

	float rayleighOpticalLength = rayleighZenithLength / zenithAngle;
	float mieOpticalLength = mieZenithLength / zenithAngle;


	// combined extinction factor
	vec3 Fex = exp(-(rayleighAtX * rayleighOpticalLength + mieAtX * mieOpticalLength));

	// in scattering
	vec3 rayleighXtoEye = rayleighAtX * RayleighPhase(cosViewSunAngle);
	vec3 mieXtoEye = mieAtX *  hgPhase(cosViewSunAngle, mieDirectionalG);

	vec3 totalLightAtX = rayleighAtX + mieAtX;
	vec3 lightFromXtoEye = rayleighXtoEye + mieXtoEye;

	vec3 somethingElse = sunE * (lightFromXtoEye / totalLightAtX);

	vec3 sky = somethingElse * (1.0 - Fex);
	sky *= mix(vec3(1.0),pow(somethingElse * Fex,vec3(0.5)),clamp(pow(1.0-dot(up, _sunDirection),5.0),0.0,1.0));
	// composition + solar disc

	float sundisk = smoothstep(_sunCosAngularDiameter,_sunCosAngularDiameter+0.00002,cosViewSunAngle);
	vec3 sun = (sunE * 19000.0 * Fex)*sundisk;

	return 0.01*(sun+sky);
}
