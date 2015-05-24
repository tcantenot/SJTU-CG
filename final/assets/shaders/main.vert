#version 140

in vec2 VertexPosition;

uniform int uFragIndex;
uniform int uFragCount;

out vec2 vTexCoord;

vec4 bounds(int i, int j, int M, int N, float dw, float dh)
{
    const vec2 MIN = vec2(-1.0, -1.0);
    const vec2 MAX = vec2(+1.0, +1.0);

    vec4 r;

    float a = i % M;
    float b = floor(float(i) / float(M));

    r.x = MIN.x + a * dw;
    r.y = MIN.y + b * dh;
    r.z = MIN.x + (a+1.0) * dw - 1.0;
    r.w = MIN.y + (b+1.0) * dh - 1.0;

    return r;
}

float mapping(vec2 from, vec2 to, float x)
{
    float a = from.x;
    float b = from.y;
    float c = to.x;
    float d = to.y;

    return (d - c) * (x - a) / (b - a) + c;
}

vec2 mapping(vec4 from, vec4 to, vec2 p)
{
    vec2 r;
    r.x = mapping(from.xy, to.xy, p.x);
    r.y = mapping(from.zw, to.zw, p.y);
    return r;
}


void main()
{
    float r = float(uFragIndex) / float(uFragCount);

    // TODO: handle non multiple of 2
    int fragCountX = int(uFragCount / 2.0);
    int fragCountY = int(uFragCount / 2.0);

    float w = (1.0 - (-1.0)) / float(fragCountX);
    float h = (1.0 - (-1.0)) / float(fragCountY);

    vec4 from = vec4(-1.0, 1.0, -1.0, 1.0);

    int i = uFragIndex % fragCountX;
    int j = uFragIndex / fragCountX;

    vec4 to;
    to.x = i * w;
    to.y = (i+1) * w - 1.0;
    to.z = j * h;
    to.w = (j+1) * h - 1.0;

    /*to = vec4(-1.0, 0.0, 0.0, -1.0);*/

    to = bounds(i, j, fragCountX, fragCountY, w, h);

    vec2 fragPos = mapping(from, to, VertexPosition.xy);

    gl_Position = vec4(fragPos, 1.0, 1.0);
    vTexCoord = VertexPosition.xy * 0.5 + 0.5;
}
