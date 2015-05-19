#version 140

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse;
uniform vec4 uTweaks;

out vec4 RenderTarget0;

/*#include "dev.glsl"*/
/*#include "pathtracer.glsl"*/
/*#include "misc/raytracer.glsl"*/
/*#include "misc/frozen_wasteland.glsl"*/
/*#include "misc/xyptonjtroz.glsl"*/
#include "misc/cloudten.glsl"

void main()
{
    vec4 color;
    mainImage(color, gl_FragCoord.xy);
    RenderTarget0 = color;
}
