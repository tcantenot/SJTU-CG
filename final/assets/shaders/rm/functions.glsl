// UTILITY FUNCTIONS ///

// See: http://www.iquilezles.org/www/articles/functions/functions.htm

// Common built-in functions:
//   smoothstep: to threshold some values and keep a smooth transition
//   pow:        to modify the constrast of a signal
//   clamp:      to clip values to a range
//   mod:        to repeat values over a space
//   mix:        to blend values
//   noise:      to enrich
//   exp:        to attenuate

////////////////////////////////////////////////////////////////////////////////
// Almost identity:
// Say you don't want to change a value unless it's too small and screws some of
// your computations up. Then, rather than doing a sharp conditional branch, you
// can blend your value with your threshold, and do it smoothly
// (say, with a cubic polynomial).
// Set m to be your threshold (anything above m stays unchanged), and n the
// value things will take when your value is zero. Then set,
//      p(0) = n
//      p(m) = m
//      p’(0) = 0
//      p’(m) = 1
// therefore, if p(x) is a cubic, then p(x) = x^3(2n-m)/m^3 + x^2(2m-3n)/m^2 + n
////////////////////////////////////////////////////////////////////////////////
float almostIdentity(float x, float m, float n)
{
    if(x > m) return x;

    const float a = 2.0 * n - m
    const float b = 2.0 * m - 3.0 * n;
    const float t = x / m;

    return (a * t + b) * t * t + n;
}


////////////////////////////////////////////////////////////////////////////////
// Impulse:
// Great for triggering behaviours or making envelopes for music or animation,
// and for anything that grows fast and then slowly decays. Use k to control the
// streching o the function.
// Btw, it's maximun, which is 1.0, happens at exactly x = 1/k.
////////////////////////////////////////////////////////////////////////////////
float impulse(float k, float x)
{
    const float h = k * x;
    return h * exp(1.0 - h);
}


////////////////////////////////////////////////////////////////////////////////
// Cubic impulse:
// Of course you found yourself doing smoothstep(c-w,c,x)-smoothstep(c,c+w,x)
// very often, probably cause you were trying to isolate some features.
// Then this cubicPulse() is your friend.
// Also, why not, you can use it as a cheap replacement for a gaussian.
////////////////////////////////////////////////////////////////////////////////
float cubicPulse(float c, float w, float x)
{
    x = abs(x - c);
    if(x > w) return 0.0;
    x /= w;
    return 1.0 - x * x * (3.0 - 2.0 * x);
}


////////////////////////////////////////////////////////////////////////////////
// Exponential step:
// A natural attenuation is an exponential of a linearly decaying quantity:
// exp(-x).
// A gaussian, is an exponential of a quadratically decaying quantity: exp(-x²).
// You can go on increasing powers, and get a sharper and sharper smoothstep(),
// until you get a step() in the limit.
////////////////////////////////////////////////////////////////////////////////
float expStep(float x, float k, float n)
{
    return exp(-k * pow(x, n));
}


////////////////////////////////////////////////////////////////////////////////
// Parabola:
// A nice choice to remap the [0, 1] interval into [0, 1], such that the corners
// are remaped to 0 and the center to 1.
// In other words, parabola(0) = parabola(1) = 0, and parabola(1/2) = 1.
////////////////////////////////////////////////////////////////////////////////
float parabola(float x, float k)
{
    return pow(4.0 * x * (1.0 - x), k);
}


////////////////////////////////////////////////////////////////////////////////
// Power curve:
// A nice choice to remap the [0, 1] interval into [0, 1], such that the corners
// are remaped to 0.
// Very useful to skew the shape one side or the other in order to make leaves,
// eyes, and many other interesting shapes.
////////////////////////////////////////////////////////////////////////////////
float pcurve(float x, float a, float b)
{
    return pow(x, a) * pow(1.0 - x, b);
}

////////////////////////////////////////////////////////////////////////////////
// Scaled power curve:
// A nice choice to remap the [0, 1] interval into [0, 1], such that the corners
// are remaped to 0.
// Very useful to skew the shape one side or the other in order to make leaves,
// eyes, and many other interesting shapes.
// Note that k is chosen such that spcurve() reaches exactly 1 at its maximum
// for illustration purposes, but in many applications the curve needs to be
// scaled anyways so the computation of k can be simply avoided (see pcurve).
////////////////////////////////////////////////////////////////////////////////
float spcurve(float x, float a, float b)
{
    float k = pow(a + b, a + b) / (pow(a, a) * pow(b , b));
    return k * pow(x, a) * pow(1.0 - x, b);
}
