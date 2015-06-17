// Raytracing or Raymarching?
#define RAYMARCHING 0

// Max ray depth
#define MAX_DEPTH 50

// Enable/Disable stratified sampling
#define STRATIFIED_SAMPLING 0

// Enable/Disable hybrid stratified sampling (stratified sampling must be enabled)
// Start with stratified sampling for a number of frame and then falls back to
// uniform sampling
#define HYBRID_STRATIFIED_SAMPLING 0

// Maximum frame number for the hybrid stratified sampling
#define HYBRID_STRATIFIED_SAMPLING_MAX_FRAME 50

#if 0

// Enable/disable importance sampling
#define IMPORTANCE_SAMPLING 1

// Enable/disable Russian Roulette ray termination
#define RUSSIAN_ROULETTE 1

// Min depth for Russian Roulette
#define RUSSIAN_ROULETTE_DEPTH 5

// Enable/Disable the direct lighting (sun and lights)
#define DIRECT_LIGHTING 1

// Enable/Disable the sun and sky lighting
#define SUN_SKY_BACKGROUND 0

// Enable/Disable the sun direct lighting
#define SUN 0

// Lights
#define LIGHTS 1

// Use the real Fresnel equations
#define REAL_FRESNEL_EQUATIONS 1

// Use Schlick's approximation for Fresnel effect if real Fresnel not used
#define FRESNEL_SCHLICK 1

// Enable glossy reflection
#define GLOSSY_REFLECTION 1

// Enable/Disable absorption and scattering
#define ABSORPTION_AND_SCATTERING 1

// Enable/disable Russian Roulette for subsurface scattering ray termination
#define RUSSIAN_ROULETTE_SSS 1

// Min depth for Russian Roulette of subsurface scattering
#define RUSSIAN_ROULETTE_SSS_DEPTH 5

// Stop ray once the reflectance has gone too low
// (the ray will probably not carry much energy)
#define LOW_REFLECTANCE_BIASED_OPTIMIZATION 0

// Minimum reflectance used for ray termination
#define MIN_REFLECTANCE 0.05

// Bias to add on metallic surface ray bounce
#define METAL_BOUNCE_BIAS 0.000

// Bias to add on total internal reflection ray bounce
#define TOTAL_REFL_BOUNCE_BIAS 0.000

// Bias to add on reflection ray bounce
#define REFL_BOUNCE_BIAS 0.000

// Bias to add on refraction ray bounce
#define REFR_BOUNCE_BIAS 0.000

// Bias to add on diffuse ray bounce
#define DIFF_BOUNCE_BIAS 0.000

// Bias to add on shadow ray bounce
#define SHADOW_BOUNCE_BIAS 0.000

#endif
