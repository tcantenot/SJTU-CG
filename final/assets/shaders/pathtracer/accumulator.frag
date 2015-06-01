#version 140

in vec2 vTexCoord;

uniform sampler2D uWorkTexture;

out vec4 RenderTarget0;

void main()
{
    RenderTarget0 = vec4(texture(uWorkTexture, vTexCoord).rgb, 1.0);
}
