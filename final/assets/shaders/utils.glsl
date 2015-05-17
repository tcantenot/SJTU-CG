/// UTITLITY FUNCTIONS ///

float max2(vec2 n)
{
    return max(n.x, n.y);
}

float max3(float x, float y, float z)
{
    return max(x, max(y, z));
}

float max3(vec3 n)
{
    return max(n.x, max(n.y, n.z));
}

float min3(float x, float y, float z)
{
    return min(x, min(y, z));
}

float min3(vec3 n)
{
    return min(n.x, min(n.y, n.z));
}

float length2(vec2 p)
{
    return sqrt(p.x * p.x + p.y * p.y);
}

float length3(vec2 p)
{
    p = p * p * p;
    return pow(p.x + p.y, 1.0 / 3.0);
}

float length4(vec2 p)
{
    p = p * p; p = p * p;
    return pow(p.x + p.y, 1.0 / 4.0);
}

float length5(vec2 p)
{
    p = p * p * p * p * p;
    return pow(p.x + p.y, 1.0 / 5.0);
}

float length6(vec2 p)
{
    p = p * p * p; p = p * p;
    return pow(p.x + p.y, 1.0 / 6.0);
}

float length7(vec2 p)
{
    p = p * p * p * p * p * p * p;
    return pow(p.x + p.y, 1.0 / 7.0);
}

float length8(vec2 p)
{
    p = p * p; p = p * p; p = p * p;
    return pow(p.x + p.y, 1.0 / 8.0);
}

float length9(vec2 p)
{
    p = p * p * p; p = p * p * p;
    return pow(p.x + p.y, 1.0 / 9.0);
}

float length10(vec2 p)
{
    p = p * p * p * p * p; p = p * p;
    return pow(p.x + p.y, 1.0 / 10.0);
}
