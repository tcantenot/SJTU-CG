/*

Simply click somewhere outside the object and drag your mouse
towards (what should be) the nearest surface. The indicator
will tell you how correct the distance field is by marching a
ray from your original click position to the new position.

The blue circles are the raymarching steps.

The bar at the bottom displays the number of raymarching steps taken.

Field colors:
 White: Positive distance
 Green: Negative distance
 Pink:  Zero distance (surface)

Dot colors:
 Blue:  Ray origin
 Red:   Ray target
 Green: Intersection

Indicator colors (bottom-left square):
 Green:  Distance is accurate.
 Yellow: Distance is too small (this is okay, just means multiple steps are needed).
 Red:    Distance is too big (this is bad).
 White:  No object was hit.

Known issues:
 It sometimes steps over objects and without turning the indicator red
 if the field is very inaccurate

*/
#version 140

#include "print.glsl"

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse = vec4(0.0);

out vec4 RenderTarget0;

const float INF = 1e20;
const int MAX_STEPS = 50;
const float DISTANCE_ACCURACY = 0.01;


// TODO: make 3D
// Put a distance function you want to test in here
float map(vec2 p)
{
    vec2 d = abs(p) - 0.5;

    /*return max(d.x, d.y); // Imperfect field*/
    /*return length(max(d, 0.0)); // Perfect unsigned field*/
    /*return length(p) - 0.5; // Perfect signed field*/
    /*return abs(length(p) - 0.75)*1.1 - 0.3; // Bad field because of scaling*/
    return length(mod(p, 0.5) - 0.25) - 0.1; // Perfect signed field
}


void main()
{
    vec2 pixel = gl_FragCoord.xy;
    float aspect = uResolution.x / uResolution.y;

    // UV
    vec2 ndc = -1.0 + 2.0 * pixel.xy / uResolution.xy;
    vec2 uv = ndc;
    uv.x *= aspect;

    // Mouse
    vec4 m = -1.0 + 2.0 * uMouse / uResolution.xyxy;
    m.xz *= aspect;


    vec3 color = vec3(0.0);

    // Background color
    float d = map(uv);
    color = vec3(1, 1, 1) * max(d, 0.0) + vec3(0, 1, 0) * max(-d, 0.0);

    // Distance field border color
    if(abs(d) < 0.005)
    {
        color = vec3(1.0, 0.0, 0.5);
    }

    // March a ray from the click pos to the current pos
    if(m.z > -aspect) // If mouse down
    {
        // Mouse: current position
        if(distance(m.xy, uv) < 0.02)
        {
            color = vec3(1.0, 0.0, 0.0);
        }

        // Mouse: click position
        if(distance(m.zw, uv) < 0.02)
        {
            color = vec3(0.0, 0.0, 1.0);
        }

        vec2 p = m.zw;
        vec2 rd = normalize(m.xy - m.zw);
        float md = 1.0;
        int ls = int(sign(map(p)));
        float steps = 0.0;
        for(int i = 0; i < MAX_STEPS; i++)
        {
            if(md < DISTANCE_ACCURACY) break;

            md = map(p);

            // The sign flipped, field is too big
            if(int(sign(md)) != ls && abs(md) > DISTANCE_ACCURACY)
            {
                m.zw = vec2(INF);
                md = 0.0;
                break;
            }

            ls = int(sign(md));
            md = abs(md);

            // Display marching steps
            float sd = distance(p, uv);
            if(sd < md && sd > md - 0.01)
            {
                color = vec3(0.2, 0.6, 0.9);
            }

            p += md * rd;
            steps++;
        }

        // Intersection point
        if(distance(p, uv) < 0.02)
        {
            color = vec3(0.0, 1.0, 0.0);
        }

        // Bottom bar: #steps
        if(uv.y < -0.95)
        {
            float ratio = steps / float(MAX_STEPS);
            if (uv.x / aspect * 0.5 + 0.5 < ratio)
            {
                color = mix(vec3(0.3, 1.0, 0.2), vec3(1.0, 0.0, 0.2), ratio);
            }
            else
            {
                color = vec3(0.150);
            }
        }

        // Hit indicator
        vec2 indicator = vec2(aspect - 0.2, 0.8);
        float total = distance(p, m.zw);
        if(ndc.x < -0.95 && ndc.y < -0.95)
        {
            // Fix for unsigned distance fields
            if(md < DISTANCE_ACCURACY && distance(p, m.zw) > 0.001)
            {
                // Distance is accurate
                if(distance(abs(map(m.zw)), total) < DISTANCE_ACCURACY)
                {
                    color = vec3(0, 1, 0);
                }
                // Distance is too big (this is bad)
                else if (m.z > (INF-1.0))
                {
                    color = vec3(1, 0, 0);
                }
                // Distance is too small (this is okay, just means multiple steps are needed).
                else if(abs(map(m.zw)) < total)
                {
                    color = vec3(1, 1, 0);
                }
            }
            else // No object was hit
            {
                color = vec3(1.0);
            }
        }

        if(ndc.x > -0.95 && ndc.x < -0.93 && ndc.y < -0.95)
        {
            color = vec3(0.150);
        }
    }

	// Multiples of 4x5 work best
    vec2 vFontSize = vec2(8.0, 15.0);
    float value = uTime;
    color = mix(color, vec3(1.0), printNumber(pixel, vec2(1.0, uResolution.y - 15.0), vFontSize, value, 9.0, 6.0));

    RenderTarget0 = vec4(color, 1.0);
}
