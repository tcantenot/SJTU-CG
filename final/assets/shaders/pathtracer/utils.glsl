/// UTITLITY FUNCTIONS ///

float mapping(vec2 from, vec2 to, float x)
{
    float a = from.x;
    float b = from.y;
    float c = to.x;
    float d = to.y;

    return (d - c) * (x - a) / (b - a) + c;
}
