// Tutorial from https://www.youtube.com/watch?v=Cfe5UQ-1L9Q
// Thanks iq!
// Shadertoy defines

#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime
#define AA 1.
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
    
    float fixedRadius2 = 2.5;
    float minRadius2 = 0.5 ;
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

vec2 DE(vec3 z, float time)
{
    z *= rotateY(time);
    float angl = (iMouse.x/iResolution.x) * 8. - 4.;
    mat3 rx = rotateX(angl);
    mat3 ry = rotateY(angl);
    mat3 rz = rotateZ(angl);
    mat3 rot = rx * ry * rz;
 
    float Scale = (iMouse.y/iResolution.y) * 8. - 4.;
    float Offset = .7;
    float n = 0.;
    float trap = 10.;

    float dr  = 1.;
    while (n < 45.) {
    
       if(z.x - z.y < 0.) z.xy = z.yx;
       if(z.x - z.z < 0.) z.xz = z.zx;
       if(z.y - z.z < 0.) z.yz = z.zy;
       z *= rot;
       z = abs(z);
       z = z*Scale - vec3(vec3(Offset*(Scale-1.0)).xy, 0);
       trap = min(trap, length(z));
       n++;
    }
    return vec2((length(z)  / abs(dr)) * pow(Scale, -float(n)), trap);
}

float getRotation(float time) 
{
    return 0.;
}

vec2 getOffset(float time) 
{
    float frames = 5.;
    time = mod(time, frames);

    float it = floor(time),
          ft = fract(time);
    
    vec2 p1 = vec2(0.04, 0.12);
    vec2 p2 = vec2(0.25, 0.25); 
    vec2 p3 = vec2(0.12, 0.17); 
    vec2 p4 = vec2(0.05, 0.17); 
    vec2 pl = vec2(0.04, 0.12);
 
    vec2 pos = pl;

    if(it < 0.5)       pos = mix(pl, p1, smoothstep(0.0, .1, ft));
    else if(it < 1.5)  pos = mix(p1, p2, smoothstep(0.6, 0.8, ft));
    else if(it < 2.5)  pos = mix(p2, p3, smoothstep(0.5, .6, ft));
    else if(it < 3.5)  pos = mix(p3, p4, smoothstep(0.0, .1, ft));
    else if(it < 4.5)  pos = mix(p4, pl, smoothstep(0.0, .1, ft));

    return pos;
}

vec2 map( in vec3 pos, float time ) 
{
    vec2 de = DE( pos , time );
    return de;
}

vec3 calcNormal( in vec3 pos, float t ) 
{
    vec2 e = vec2(0.001, 0.0);
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
        if ( res<0.001 ) break;
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

mat3 camRotation(float time)
{
    return rotateX(0.0) * rotateY(time) * rotateZ(0.);
}
 
void main() {

    float time = iTime;
    time /= 8.;

    vec3 col = vec3(0);
    vec3 res = vec3(0);
    
    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y;
        
        mat3 rot = camRotation( time );

        vec3 cp = vec3(0.25,0.5,-10.);
        vec3 ta = vec3(0.,-0.6,0);
        vec3 ro = vec3(0,1,1) + cp;

        vec3 ww = normalize( ta-ro );
        vec3 uu = normalize( cross(ww, vec3(0,1,0)) );
        vec3 vv = normalize( cross(uu,ww) );

        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );
 
        vec3 col = vec3(0);

        vec2 tm = castRay(ro, rd, time); 

        if( tm.x < 20. )
        {
            float t = tm.x;
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos, time);

            vec3 mate = cos(vec3(0,2,1.5) + tm.y*6. + 5.72 + time);

            vec3 sun_dir = normalize( ro - vec3(0,0.2,2) );
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
