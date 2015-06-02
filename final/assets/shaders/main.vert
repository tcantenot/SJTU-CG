#version 140

in vec2 VertexPosition;

out vec2 vTexCoord;

void main()
{
    gl_Position = vec4(VertexPosition.xy, 1.0, 1.0);
    vTexCoord = VertexPosition.xy * 0.5 + 0.5;
}
