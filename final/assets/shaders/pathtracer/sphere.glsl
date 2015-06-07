#include "material.glsl"

struct Sphere
{
	float radius;
	vec3 pos;
    Material material;
    bool collidable;
};
