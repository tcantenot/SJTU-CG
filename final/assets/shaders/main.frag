#version 330

in vec2 vTexCoord;

uniform vec4  uMouse;
uniform int   uIterations;
uniform vec2  uResolution;
uniform float uTime;
uniform vec4  uTweaks;

uniform sampler2D uTexture0;
uniform sampler2D uTexture1;
uniform sampler2D uTexture2;
uniform sampler2D uTexture3;
uniform sampler2D uTexture4;
uniform sampler2D uTexture5;

out vec4 RenderTarget0;

/*#include "debug/test_random.glsl"*/
#include "pathtracer/pathtracer.glsl"

void main()
{
    vec4 color;
    mainImage(color, gl_FragCoord.xy);
    RenderTarget0 = color;
}
