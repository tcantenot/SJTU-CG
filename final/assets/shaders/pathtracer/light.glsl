////////////////////////////////////////////////////////////////////////////////
/// \brief Structure representing a light volume.
////////////////////////////////////////////////////////////////////////////////
struct Light
{
    vec3 pos;     ///< Position of the light
    float radius; ///< Radius of the light
    vec3 color;   ///< Color of the light
    float power;  ///< Power of the light
};


#include "ray.glsl"

////////////////////////////////////////////////////////////////////////////////
/// \brief Compute the distance between the ray origin and the light.
/// \param ray Ray.
/// \param light Light.
/// \return The distance between the ray origin and the light if the ray hit the
/// volume, INF otherwise.
////////////////////////////////////////////////////////////////////////////////
float distanceTo(Ray ray, Light light)
{
    const float INF = 1e5;
    const float EPSILON = 1e-3;

	vec3 op = light.pos - ray.origin;
    float b = dot(op, ray.direction);
    float det = b * b - dot(op, op) + light.radius * light.radius;

	if(det < 0.0) // No intersection
    {
        return INF;
    }
    else
    {
        det = sqrt(det);
    }

	float t;
	return (t = b - det) > EPSILON ? t : ((t = b + det) > EPSILON ? t : INF);
}
