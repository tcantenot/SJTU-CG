#version 140

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse;
uniform vec4 uTweaks;

uniform sampler2D uTexture0;
uniform sampler2D uTexture1;

out vec4 RenderTarget0;

/*#include "dev.glsl"*/
/*#include "pathtracer.glsl"*/
/*#include "misc/raytracer.glsl"*/
/*#include "misc/frozen_wasteland.glsl"*/
/*#include "misc/xyptonjtroz.glsl"*/
/*#include "misc/cloudten.glsl"*/
/*#include "misc/noisetex.glsl"*/

void main()
{
    vec4 color;
    mainImage(color, gl_FragCoord.xy);
    RenderTarget0 = color;
}
