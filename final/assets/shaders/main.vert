#version 140

in vec2 VertexPosition;

uniform int uFragCount;   // Total fragment count
uniform int uFragIndex;   // Current fragment index
uniform vec4 uFragBounds; // Current fragment bounds in NDC coordinates

out vec2 vTexCoord;

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
    vec4 from = vec4(vec2(-1.0, 1.0), vec2(-1.0, 1.0));
    vec4 to = uFragBounds;

    vec2 fragPos = mapping(from, to, VertexPosition.xy);

    gl_Position = vec4(fragPos, 1.0, 1.0);
    vTexCoord = VertexPosition.xy * 0.5 + 0.5;
}
