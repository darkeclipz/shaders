# Fractals

## boxFold

```glsl
// https://github.com/HackerPoet/MarbleMarcher/blob/master/assets/frag.glsl
vec3 boxFold(vec3 z, vec3 r) {
	return clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}
```

## sphereFold

```glsl
// http://www.fractalforums.com/fragmentarium/fragmentarium-an-ide-for-exploring-3d-fractals-and-other-systems-on-the-gpu/15/
void sphereFold(inout vec3 z, inout float dz) {
    
    float fixedRadius2 = .6 + 4.* cos(20./8.) + 4.;
    float minRadius2 = 0.3;
	float r2 = dot(z,z);
	if (r2< minRadius2) {
		float temp = (fixedRadius2/minRadius2);
		z*= temp;
		dz*=temp;
	} 
    else if (r2<fixedRadius2) {
		float temp =(fixedRadius2/r2);
		z*=temp;
		dz*=temp;
	}
}
```

## mengerFold

```glsl
// https://github.com/HackerPoet/MarbleMarcher/blob/master/assets/frag.glsl
vec3 mengerFold(vec3 z) {
	float a = min(z.x - z.y, 0.0);
	z.x -= a;
	z.y += a;
	a = min(z.x - z.z, 0.0);
	z.x -= a;
	z.z += a;
	a = min(z.y - z.z, 0.0);
	z.y -= a;
	z.z += a;
    return z;
}
```

## Mandelbox Variant 1

![mandelbox](https://github.com/darkeclipz/shaders/blob/master/screenshots/mandelbox_de_variant1.png)

```glsl
// http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/
vec2 DE(vec3 z)
{
    float Iterations = 8.;
    float Scale = 4.4 + 1. + 0.4;
	vec3 offset = z;
	float dr = 1.0;
    float trap = 1e10;
	for (float n = 0.; n < Iterations; n++) {
        
        z = mengerFold(z);
        z = boxFold(z, vec3(2.));       // Reflect

        z.xz = -z.zx;
		z = boxFold(z, vec3(1.));       // Reflect
        
		sphereFold(z, dr);    // Sphere Inversion
        z=Scale*z + offset;  // Scale & Translate
        dr = dr*abs(Scale)+1.0;
        trap = min(trap, length(z));
	}
	float r = length(z);
	return vec2(r/abs(dr), trap);
}
```

## Mandelbox Variant 2

![mandelbox 2](https://github.com/darkeclipz/shaders/blob/master/screenshots/mandelbox_de_variant2.png)


```glsl
// http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/
vec2 DE(vec3 z)
{
    float Iterations = 8.;
    float Scale = 3.5 + (sin(3.14*2.0*(iMouse.x/iResolution.x))*.5+.5)*2.3;
	vec3 offset = z;
	float dr = 1.0;
    float trap = 1e10;
	for (float n = 0.; n < Iterations; n++) {
        
        //z = mengerFold(z);
        z = boxFold(z, vec3(1.1));       // Reflect
        sphereFold(z, dr);    // Sphere Inversion
        //z.xz = -z.zx;
		z = boxFold(z, vec3(1.8));       // Reflect
        
		sphereFold(z, dr);    // Sphere Inversion
        z=Scale*z + offset;  // Scale & Translate
        dr = dr*abs(Scale)+1.0;
        trap = min(trap, length(z));
	}
	float r = length(z);
	return vec2(r/abs(dr), trap);
}
```

## Kleinian 

![Kleinian 1](https://github.com/darkeclipz/shaders/blob/master/screenshots/shadertoy24.png)

![Kleinian 2](https://github.com/darkeclipz/shaders/blob/master/screenshots/shadertoy25.png)

```glsl
vec2 DE(vec3 p, float s)
{
	float scale = 1.0;
    vec4 orb;

    s = 1.525 - 0.44 + iMouse.x/iResolution.x - 0.5;

	orb = vec4(1000.0); 
	
	for( int i=0; i<8;i++ )
	{
		p = -1.0 + 2.0*fract(0.5*p+0.5);

		float r2 = dot(p,p);
		
        orb = min( orb, vec4(abs(p),r2) );
		
		float k = s/r2;
		p     *= k;
		scale *= k;
	}
	
	return vec2(0.25*abs(p.y)/scale, orb.w);
}
```