#version 140

in vec2 vTexCoord;

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uMouse = vec4(0.0);

out vec4 RenderTarget0;



/*

Simply click somewhere outside the object and drag your mouse
towards (what should be) the nearest surface. The indicator
will tell you how correct the distance field is by marching a
ray from your original click position to the new position.

The green circles are the raymarching steps.

The bar at the bottom displays the number of raymarching steps taken.

Field colors:
White: Positive distance
Green: Negative distance
Pink: Zero distance (surface)

Dot colors:
Blue: Ray origin
Red: Ray target
White: Intersection

Indicator colors:
Green: Distance is accurate.
Yellow: Distance is too small (this is okay, just means multiple steps are needed).
Red: Distance is too big (this is bad).
Blue: No object was hit.

Known issues:
It sometimes steps over objects and without turning the indicator
red if the field is very inaccurate

*/

const float ACCURATE_DIST = 0.01;
const int NUM_MARCH_ITER = 50;

// Put a distance function you want to test in here
// TODO: make 3D
float map(vec2 p)
{
	vec2 d = abs(p) - 0.5;

    return max(d.x, d.y); // Imperfect field
    /*return length(max(d, 0.0)); // Perfect unsigned field*/
	//return length(p) - 0.5; // Perfect signed field
	//return abs(length(p) - 0.75)*1.1 - 0.3; // Bad field because of scaling
	//eturn length(mod(p, 0.5) - 0.25) - 0.1; // Perfect signed field
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
	float aspect = uResolution.x / uResolution.y;
	vec2 indicator = vec2(aspect - 0.3, 0.7);
	vec2 uv = -1.0 + 2.0 * fragCoord.xy / uResolution.xy;
	uv.x *= aspect;
    vec4 mouse = uMouse;
	vec4 m = -1.0 + 2.0 * mouse / uResolution.xyxy;
	m.xz *= aspect;

	vec3 color = vec3(0.0);

	// Background color
	float d = map(uv);
    color = vec3(1, 1, 1) * max(d, 0.0) +
	        vec3(0, 1, 0) * max(-d, 0.0);

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
		for(int i = 0; i < NUM_MARCH_ITER; i++)
        {
			if(md < ACCURATE_DIST) continue;

			md = map(p);

			// The sign flipped, field is too big
			if(int(sign(md)) != ls && abs(md) > ACCURATE_DIST)
            {
				m.zw = vec2(1000.0);
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
                /*float ratio = steps/float(NUM_MARCH_ITER);*/
                /*color = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), ratio);*/
            }

			p += md * rd;
			steps++;
		}

        // Intersection point
		if(distance(p, uv) < 0.02)
        {
			color = vec3(0.0, 1.0, 0.0);
        }

		// Indicator
		float total = distance(p, m.zw);
		if (distance(uv, indicator) < 0.1) {
			if (md < ACCURATE_DIST &&
					distance(p, m.zw) > 0.001) { // Fix for unsigned distance fields
				if (distance(abs(map(m.zw)), total) < ACCURATE_DIST)
					color = vec3(0, 1, 0);
				else if (m.z > 999.0)
					color = vec3(1, 0, 0);
				else if (abs(map(m.zw)) < total)
					color = vec3(1, 1, 0);
			} else {
				color = vec3(0, 0, 1);
			}
		} else if (distance(uv, indicator) < 0.15) {
			color = vec3(0);
		}

		// # steps bottom bar
		if(-uv.y > 0.95)
        {
            float ratio = steps/float(NUM_MARCH_ITER);
			if (uv.x/aspect * 0.5 + 0.5 < ratio)
            {
                color = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), ratio);
            }
			else
            {
				color = vec3(1.0);
            }
		}
	}

	RenderTarget0 = vec4(color, 1.0);
}
