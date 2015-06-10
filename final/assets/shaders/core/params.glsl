////////////////////////////////////////////////////////////////////////////////
/// Fragment shader input parameters.
////////////////////////////////////////////////////////////////////////////////
struct Params
{
    vec2 pixel;      // Current pixel in window space [0, w] x [0, h]
    vec2 resolution; // Resolution of the screen in pixel (w, h)
    vec4 mouse;      // Mouse xy: mouse position, zw: mouse click
    float time;      // Time since app started
};
