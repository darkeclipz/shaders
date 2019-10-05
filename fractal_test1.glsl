// Tutorial from https://www.youtube.com/watch?v=Cfe5UQ-1L9Q
// Thanks iq!
// Shadertoy defines

#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime

#define R iResolution.xy



float smin( in float a, in float b, float k )
{
    float h = max( k - abs(a-b), 0.0 );
    return min(a,b) - h*h/(k*4.0);
}

float smax( in float a, in float b, float k )
{
    float h = max( k - abs(a-b), 0.0 );
    return max(a,b) + h*h/(k*4.0);
}

mat3 rotateZ(float angle) {
	float c = cos(angle), s = sin(angle);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

float sdSphere(vec3 p, float r) {
	return length(p) - r;    
} 

// from iq
float sdPlane(in vec3 p, in vec4 n)
{
  return dot(p,n.xyz) + n.w;
}

// from iq
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
        
}

// https://github.com/HackerPoet/MarbleMarcher/blob/master/assets/frag.glsl
vec3 boxFold(vec3 z, vec3 r) {
	return clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}

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

vec2 map( in vec3 pos ) 
{
    float cr = 0.10;
    vec2 d1 = DE(pos + vec3(0.));
    //d1.y = 1.0;

    return d1;
}

vec3 calcNormal( in vec3 pos ) 
{
    vec2 e = vec2(0.0005, 0.0);
    return normalize( vec3(map(pos+e.xyy).x-map(pos-e.xyy).x,
                           map(pos+e.yxy).x-map(pos-e.yxy).x,
                           map(pos+e.yyx).x-map(pos-e.yyx).x ) );
}

float castShadow( in vec3 ro, vec3 rd )
{
    float res = 1.0;
    //return res;
    float t = 0.01;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro + t*rd;
        float h = map( pos ).x;
        res = min( res, 16.0*h/t );
        if ( res<0.01 ) break;
        t += h;
        if( t > 10.0 ) break;
    }

    return clamp(res,0.0,1.0);
} 

vec2 castRay( in vec3 ro, vec3 rd )
{
    float m = -1.0;
    float t = 0.0;
    for( int i=0; i<120; i++ )
    {
        vec3 pos = ro + t*rd;

        vec2 h = map( pos );
        m = h.y;
        if( h.x<0.0005 )
            break;
        t += h.x;
        if( t>100.0 )
            break;
    } 
    if( t>100.0 ) m=-1.0;
    return vec2(t,m);
}

#define AA 1.
 
void main() {
    float time = iTime;
    vec3 col = vec3(0);
    vec3 res = vec3(0);
    
    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y;
        float an = 10.0*(0.94+sin(iTime/16.)*0.02);
        
        vec3 ta = vec3(-2.05,0.5  ,7.);   
        an = 0.8 + 0.21*(-cos(iTime / 16.)*0.5+0.5) - 0.1 ;
        
        vec3 rot = vec3(1.0*sin(an), 0.0, 1.0*cos(-an));
        vec3 ro = ta + vec3(0.,1.0,-20.) * rot;
        
        vec3 ww = normalize( ta-ro );
        vec3 uu = normalize( cross(ww, vec3(0,1,0)) );
        vec3 vv = normalize( cross(uu,ww) );

        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );

        vec3 col = vec3(0.1) - 0.65*rd.y;

        vec2 tm = castRay(ro, rd);

        if( tm.y>0.0 )
        {
            float t = tm.x;
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);

            vec3 mate = vec3(0.18); 

            if( tm.y < 1.5 )
            {
                mate = vec3(1,0,0);
            }
    
            vec3 sun_dir = normalize( ro + vec3(3.,  4.7, -8.0) );
            float sun_dif = clamp( dot(nor,sun_dir),0.0,1.0); 
            float sun_sha = 0.75*castShadow( pos+nor*0.001, sun_dir );
            float sky_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0);
            float bou_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

            col  = mate*vec3(5.0,4.5,4.0)*sun_dif*sun_sha;
            //col += mate*vec3(0.5,0.6,0.6)*sky_dif;
            col += 0.5*mate*vec3(0.5,0.6,0.6)*bou_dif;
        }

        res += clamp(col, 0.0, 1.0);
    }

    col = pow( res/(AA*AA), vec3(0.4545) );
    
    O = vec4(col, 1.0);
}
