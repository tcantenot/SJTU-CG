
// Transforms

void T(inout float p, float t)
{
    p += t;
}

void Tx(inout vec3 p, float t)
{
    p.x += t;
}

void Ty(inout vec3 p, float t)
{
    p.y += t;
}

void Tz(inout vec3 p, float t)
{
    p.z += t;
}

void Rx(inout vec3 p, float a)
{
	float c,s;vec3 q=p;
	c = cos(a); s = sin(a);
	p.y = c * q.y - s * q.z;
	p.z = s * q.y + c * q.z;
}

void Ry(inout vec3 p, float a) {
	float c,s;vec3 q=p;
	c = cos(a); s = sin(a);
	p.x = c * q.x + s * q.z;
	p.z = -s * q.x + c * q.z;
}

void Rz(inout vec3 p, float a) {
	float c,s;vec3 q=p;
	c = cos(a); s = sin(a);
	p.x = c * q.x - s * q.y;
	p.y = s * q.x + c * q.y;
}
void RxCS(inout vec3 p, float c, float s) {
	vec3 q=p;
	p.y = c * q.y - s * q.z;
	p.z = s * q.y + c * q.z;
}


void RyCS(inout vec3 p, float c, float s) {
	vec3 q=p;
	p.x = c * q.x + s * q.z;
	p.z = -s * q.x + c * q.z;
}

void RzCS(inout vec3 p, float c, float s) {
	vec3 q=p;
	p.x = c * q.x - s * q.y;
	p.y = s * q.x + c * q.y;
}
