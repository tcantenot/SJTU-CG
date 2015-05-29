#version 330

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse;
uniform vec4 uTweaks;

uniform float uSeed;

uniform sampler2D uTexture0;
uniform sampler2D uTexture1;
uniform sampler2D uTexture2;
uniform sampler2D uTexture3;
uniform sampler2D uTexture4;
uniform sampler2D uTexture5;

out vec4 RenderTarget0;

/*#include "dev.glsl"*/
/*#include "pathtracer.glsl"*/
/*#include "misc/raytracer.glsl"*/
/*#include "misc/frozen_wasteland.glsl"*/
/*#include "misc/xyptonjtroz.glsl"*/
/*#include "misc/cloudten.glsl"*/
/*#include "misc/noisetex.glsl"*/
/*#include "misc/elevated.glsl"*/
/*#include "scenes/canyon.glsl"*/
/*#include "misc/smallpt.glsl"*/
/*#include "smallpt.glsl"*/
#include "pathtracer/pathtracer.glsl"
/*#include "fragmentarium/skypathtracer.glsl"*/

void main()
{
    vec4 color;
    mainImage(color, gl_FragCoord.xy);
    RenderTarget0 = color;
}
