/// UTITLITY FUNCTIONS ///

////////////////////////////////////////////////////////////////////////////////
/// Map a variable from a origin interval to a destination interval.
/// \param from Origin interval [a, b].
/// \param to   Destination interval [c, d].
/// \param x    Value in origin interval [a, b].
/// \return The corresponding value of x in the destination interval [c, d].
////////////////////////////////////////////////////////////////////////////////
float mapping(vec2 from, vec2 to, float x)
{
    float a = from.x;
    float b = from.y;
    float c = to.x;
    float d = to.y;

    return (d - c) * (x - a) / (b - a) + c;
}
