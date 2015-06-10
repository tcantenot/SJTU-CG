////////////////////////////////////////////////////////////////////////////////
/// Camera class defining the point of view of the rendered scene.
////////////////////////////////////////////////////////////////////////////////
struct Camera
{
    vec3 position;  // Position of the camera
    float aperture; // Aperture
    vec3 target;    // Target of the camera (defines a forward direction)
    float roll;     // Roll
    vec2 fov;       // Field of view in degree
    float focal;    // Focal distance
    float _padding; // Struct padding
};
