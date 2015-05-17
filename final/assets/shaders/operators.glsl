// Distance field operators
//
// From:
// - http://iquilezles.org/www/articles/distfunctions/distfunctions.htm


// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

float opU(float d1, float d2, inout bool first)
{
    first = d1 <= d2;
    return first ? d1 : d2;
}

float opU(float d1, float d2, int id1, int id2, inout int id)
{
    bool first = false;
    float d = opU(d1, d2, first);
    id = first ? id1 : id2;
    return d;
}

// Intersection
float opI(float d1, float d2)
{
    return max(d1, d2);
}

// Substraction
float opS(float d1, float d2)
{
    return max(d1, -d2);
}

// Complementary
// /!\ d must be a signed distance
float opC(float d)
{
    return -d;
}

// The distance field resulting for the twist operation needs a correction
// -> see opTwistLip
vec3 opTwist(vec3 p, const float a, const float b)
{
    // Linear function of the third axis (twist axis)
    /*const float a = 10.0;*/
    /*const float b = 10.0;*/
    float f = a * p.y + b;

    float  c = cos(f);
    float  s = sin(f);
    mat2   m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}

// Lipschitz constant of the twisting deformation used to correct the distance field
// -> multiply the distance field by this constant
// twist(x, y, z) = mat2(x * cos(f(z)), -y * sin(f(z)), x * sin(f(z)), y * cos(f(z)))
// where f(z) is a linear function of the third axis (i.e the twist axis)
// Lip(twist) = sqrt(4 + (pi/f')^2)
// where f' is the derivative of the linear function f of the twist
// Converge towards 0.5
float opTwistLip(const float a)
{
    const float Pi = 3.141592654;
    const float lip = 1.0 / sqrt(4.0 + pow(Pi / a, 2.0));
    return lip; // a -> +inf => lip -> 0.5
}


// COMBINATIONS ("smooth unions")

float opCombine(float d1, float d2, float r)
{
    float m = min(d1, d2);
    float rd1 = r - d1;
    float rd2 = r - d2;
    return (rd1 > 0 && rd2 > 0) ? min(m, r - sqrt(rd1 * rd1 + rd2 * rd2)) : m;
}

// Derived from Johann Korndorfer's technique: https://www.youtube.com/watch?v=s8nFqwOho-s
float opCombineChamfer(float d1, float d2, float r)
{
    float m = min(d1, d2);

    if(d1 < r && d2 < r)
    {
        return min(m, d1 + (d2 - r));
    }
    else
    {
        return m;
    }
}

// Intersection d1 with everything that is not d2
float opDivide(float d1, float d2)
{
    return opI(d1, -d2);
}

// Derived from Johann Korndorfer's technique: https://www.youtube.com/watch?v=s8nFqwOho-s
float opDivideChamfer(float d1, float d2, float r)
{
    float m = max(d1, -d2);

    if(d1 < r && d2 < r)
    {
        return max(m, d1 - (d2 - r));
    }
    else
    {
        return m;
    }
}

// REPETITIONS

vec3 opRep(vec3 p, vec3 c)
{
    return mod(p, c) - 0.5 * c;
}

////////////////////////////////////////////////////////////////////////////////
/// \brief Repetition operator along one dimension.
/// \param[inout] p Coordinate in the dimension to do the repetition in which
///                 is modified into the coordinate of the current repetition.
/// \param size     Spacing between two repetition.
/// \return The index of the repetition (negative on the left side, positive on
/// the right size).
////////////////////////////////////////////////////////////////////////////////
float opRep1(inout float p, float size)
{
    float halfSize = size * 0.5;
    p += halfSize;
    float i = floor(p / size);
    p = mod(p, size) - halfSize;
    return i;
}

float opMirror2(inout vec2 p, vec2 b)
{
    vec2 ap = abs(p) - b;
    if(ap.x > ap.y) p = p.yx;
    return 1.0;
}


float opRepMirror1(inout float p, float size)
{
    float halfSize = size * 0.5;
    p += halfSize;
    float i = floor(p / size);
    p = mod(p, size) - halfSize;
    p *= mod(i, 2.0) * 2.0 - 1.0;
    return i;
}

vec2 opRepMirror2(inout vec2 p, vec2 size)
{
    float halfSize = size * 0.5;
    p += halfSize;
    vec2 i = floor(p / size);
    p = mod(p, size) - halfSize;
    p *= mod(i, vec2(2.0)) * 2.0 - 1.0;
    return i;
}

float opRepSingle1(inout float p, float size)
{
    float halfSize = size * 0.5;
    p += halfSize;
    float i = floor(p / size);
    if(p <= 0) p = mod(p, size) - halfSize;
    return i;
}

float opRepInterval1(inout float p, float size, float beg, float end)
{
    float halfSize = size * 0.5;
    p += halfSize;
    float i = floor(p / size);
    if(i > end)
    {
        p += size * (i - end);
        i = end;
    }
    if(i < beg)
    {
        p += size * (i - beg);
        i = beg;
    }

    return i;
}

float opRepAngleWithAtan(inout vec2 p, float reps, float at)
{
    const float TwoPi = 2.0 * 3.141592654;
    float angle = TwoPi / reps;
    float halfAngle = angle / 2.0;

    float a = at + halfAngle;
    float r = length(p);
    float i = floor(a / angle);
    a = mod(a, angle) - halfAngle;
    p = vec2(cos(a), sin(a)) * r;

    if(abs(i) >= (reps / 2.0)) i = abs(i);
    return i;
}

float opRepAngle(inout vec2 p, float reps)
{
    return opRepAngleWithAtan(p, reps, atan(p.y, p.x));
}

float opRepAngleMirrorWithAtan(inout vec2 p, float reps, float at)
{
    const float Pi    = 3.141592654;
    const float TwoPi = 2.0 * Pi;
    float angle = TwoPi / reps;
    float halfAngle = angle / 2.0;

    float a = at + halfAngle;
    a += Pi / reps;

    float r = length(p);
    float i = floor(a / angle);
    if(mod(i, 2.0) == 1.0)
    {
        a = angle - a;
    }
    a = mod(a, angle) - halfAngle;
    p = vec2(cos(a), sin(a)) * r;
    return i;
}

float opRepAngleMirror(inout vec2 p, float reps)
{
    return opRepAngleMirrorWithAtan(p, reps, atan(p.y, p.x));
}
