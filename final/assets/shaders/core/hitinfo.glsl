////////////////////////////////////////////////////////////////////////////////
/// Structure containing the information related to a hit
/// (ray-primitive intersection).
////////////////////////////////////////////////////////////////////////////////
struct HitInfo
{
    int id;      // Id of the hit primitive (usually negative if nothing hit)
    vec3 pos;    // Position of the intersection
    float dist;  // Distance of the intersection (from the ray's origin)
    vec3 normal; // Unit normal at the intersection point
    vec3 cell;   // Cell index (used by raymarching of distance fields to
                 // uniquely identify among the repetitions of a primitive)
    //vec3 uvw;  // Texture coordinates
};
