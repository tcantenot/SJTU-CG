
// "Ping-pong" animation:
// When cosine is below m: state 1
// When cosine is above M: state 2
// When cosine is in between, smooth interpolation of states 1 and 2
float anim1(float m, float M, float t)
{
    const float a = 0.5;
    smoothstep(m, M, -cos(a * t));
}
