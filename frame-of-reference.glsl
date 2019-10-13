// Tutorial from https://www.youtube.com/watch?v=Cfe5UQ-1L9Q
// Thanks iq!
// Shadertoy defines

#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime
#define AA 2.
#define R iResolution.xy
float Mx() 
{
    return iMouse.x / iResolution.x;
}

float My()
{
    return iMouse.y / iResolution.y;
}

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

mat3 rotateX(float angle) {
	float c = cos(angle), s = sin(angle);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotateY(float angle) {
	float c = cos(angle), s = sin(angle);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
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
    
    float fixedRadius2 = 1.3;
    float minRadius2 = 0.1;
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

float DE(vec3 z)
{
    vec3 orig = vec3(z);
    float Iterations = 14.;
    float Scale = 2.0;
    float Offset = 1.5;
    float n = 0.;
    while (n < Iterations) {
       if(z.x+z.y<0.) z.xy = -z.yx; // fold 1
       if(z.x+z.z<0.) z.xz = -z.zx; // fold 2
       if(z.y+z.z<0.) z.zy = -z.yz; // fold 3     
       z = z*Scale - Offset*(Scale-1.0);
       n++;
    }
    float yPlane = length(vec3(0,-.01,0) - orig);
    return min(yPlane, (length(z) ) * pow(Scale, -float(n)));
}

vec2 sdReferenceAxis( in vec3 pos )
{
    float id = 0.;
    float r = 0.01;
    float d = sdBox( pos + vec3(0.5,0,0), vec3(0.5,r,r) );
    float d2 = sdBox( pos + vec3(0,0.5,0), vec3(r, 0.5, r));
    if(d2 < d) id = 1.;
    d = min(d, d2);
    d2 = sdBox( pos + vec3(0,0,0.5), vec3(r, r, 0.5));
    if(d2<d) id = 2.;
    d = min(d,d2);
    return vec2(d,id);
}

float getRotation(float time) 
{
    return 0.;
}

vec2 map( in vec3 pos, float time ) 
{
    float id = 0.;

    float d = sdPlane( pos , vec4(0,1,0,1) );

    float d2 = DE( pos * rotateX((0.90+0.002)*3.14*2.) * rotateZ(3.14/4.) - vec3(0,-0.22,0) );

    if(d2 < d) id = 1.;
    d = min(d2, d);

    vec2 ref = sdReferenceAxis( pos );
    if(ref.x < d) id = ref.y + 2.0;
    d = min(ref.x, d); 

    d2 = sdSphere( pos - vec3(0.3,0.05,0), 0.025 );
    if(d2<d) id = 2.;
    d = min(d, d2);

    return vec2(d, id);
}

vec3 calcNormal( in vec3 pos, float t ) 
{
    vec2 e = vec2(0.0001, 0.0);
    return normalize( vec3(map(pos+e.xyy,t).x-map(pos-e.xyy,t).x,
                           map(pos+e.yxy,t).x-map(pos-e.yxy,t).x,
                           map(pos+e.yyx,t).x-map(pos-e.yyx,t).x ) );
}

float castShadow( in vec3 ro, vec3 rd, float time )
{
    float res = 1.0;
    float t = 0.00;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro + t*rd;
        float h = map( pos, time ).x;
        res = min( res, 16.0*h/t );
        if ( res<0.01 ) break;
        t += h;
        if( t > 10.0 ) break;
    }

    return clamp(res,0.0,1.0);
} 

vec2 castRay( in vec3 ro, vec3 rd, float time )
{
    float m = -1.0;
    float t = 0.0;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro + t*rd;

        vec2 h = map( pos, time );
        m = h.y;
        if( h.x<0.001 )
            break;
        t += h.x;
        if( t>20.0 )
            break;
    } 
    if( t>20.0 ) m=-1.0;
    return vec2(t,m);
}


vec3 camPos(float time) 
{
    float frames = 5.;
    time = mod(time, frames);

    float it = floor(time),
          ft = fract(time);


    vec3 p1 = vec3(1.6,-0.2,1.) * rotateY(3.14/3.);
    vec3 p2 = vec3(1.6,-0.2,1.) * rotateY(3.14/3.) + vec3(0,0,-1.9); 
    vec3 p3 = vec3(1.2,-0.2,1.6) ; 
    vec3 p4 = vec3(1.2,-0.2,1.6) * rotateY(3.14/4.); 
    vec3 pl = vec3(1.6,-0.2,1.);
    
    vec3 pos = pl;

    
    if(it < 0.5)       pos = mix(pl, p1, smoothstep(0.0, 1., ft));
    else if(it < 1.5)  pos = mix(p1, p2, smoothstep(0.0, 1., ft));
    else if(it < 2.5)  pos = mix(p2, p3, smoothstep(0.0, 1., ft));
    else if(it < 3.5)  pos = mix(p3, p4, smoothstep(0.0, 1., ft));
    else if(it < 4.5)  pos = mix(p4, pl, smoothstep(0.0, 1., ft));

    return pos * 2.0;

    return vec3(1,0,1) * rotateY(time);
}

mat3 camRotation(float time)
{
    return rotateX(0.0) * rotateY(time) * rotateZ(0.);
}
 
void main() {

    float time = iTime;
    time /= 3.;

    vec3 col = vec3(0);
    vec3 res = vec3(0);
    
    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y;
        
        mat3 rot = camRotation( time );

        vec3 ta = vec3(0.3,0.05,0);
        vec3 ro = camPos( time );

        vec3 ww = normalize( ta-ro );
        vec3 uu = normalize( cross(ww, vec3(0,1,0)) );
        vec3 vv = normalize( cross(uu,ww) );

        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );
 
        vec3 col = mix(vec3(22, 94, 214) / 255., vec3(0, 33, 140) / 255., p.y);

        vec2 tm = castRay(ro, rd, time); 

        if( tm.x < 20. )
        {
            float t = tm.x;
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos, time);

            vec3 mate = vec3(0.18); 

            if(tm.y < 0.5) {
                vec2 checker = trunc(fract(pos.xz)*4.);
                float cm = (mod(checker.x + checker.y, 2.0) == 0.0) ? 1. : 0.;
                mate = vec3(0.01) * cm + (1.-cm) * vec3(0.02);
            }
            else if(tm.y < 1.5) {
                mate = vec3(0.6);
            }
            else if(tm.y < 2.5) {
                mate = vec3(1,0,0);
            }
            else if(tm.y < 3.5) {
                mate = vec3(0,1,0);
            }
            else if(tm.y < 4.5) {
                mate = vec3(0,0,1);
            }
            else if(tm.y < 4.5) {
                mate = vec3(1,0,0);
            }

            vec3 sun_dir = normalize( vec3(1.,1.,1.) * rotateY(3.14/4.*8.) );
            float sun_dif = clamp( dot(nor,sun_dir),0.0,1.0); 
            float sun_sha = 0.75*castShadow( pos+nor*0.001, sun_dir, time );
            float sky_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0);
            float bou_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

            col  = mate*vec3(5.0,4.5,4.0)*sun_dif*sun_sha;
            col += mate*vec3(0.5,0.6,0.6)*sky_dif;
            col += mate*vec3(0.5,0.6,0.6)*bou_dif;
        }

        res += clamp(col, 0.0, 1.0);
    }

    col = pow( res/(AA*AA), vec3(0.4545) );
    
    O = vec4(col, 1.0);
}
