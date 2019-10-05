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

float sdTorus( in vec3 p, float r1, float r2) 
{
    return length(vec2(length(p.xz) - r1, p.y)) - r2;
}

vec2 circleFold(vec2 z, float fixedRadius2, float minRadius2) {
    float r2 = dot(z,z);
    if(r2 < minRadius2)        return z * (fixedRadius2 / minRadius2);
    else if(r2 < fixedRadius2) return z * (fixedRadius2 / r2);
    return z;
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

float sdWorld( in vec3 p ) 
{    
    float d1 = sdSphere( p - vec3(-1.5, 0, 0), 0.3 );
    float d2 = sdBox( p, 0.5*normalize(vec3(1,1,1)) );
    d1 = min(d1, d2);
    d2 = sdTorus( (p - vec3(1.5,0,0))*rotateZ(3.14/2.)*rotateY(iTime) , 0.25, 0.125 );
    d1 = min(d1, d2);
    return d1;
}

vec2 map( in vec3 pos ) 
{
    float cr = 0.10;
    float d = sdPlane( pos, vec4(0,1,0,1) );
    float id = 1.0;
    float d2 = sdWorld( pos - vec3(0,-0.7,0) );
    if( d2 < d ) id = 2.0;
    d = min(d, d2);
    return vec2(d, id);
}

vec3 calcNormal( in vec3 pos ) 
{
    vec2 e = vec2(0.0001, 0.0);
    return normalize( vec3(map(pos+e.xyy).x-map(pos-e.xyy).x,
                           map(pos+e.yxy).x-map(pos-e.yxy).x,
                           map(pos+e.yyx).x-map(pos-e.yyx).x ) );
}

float castShadow( in vec3 ro, vec3 rd )
{
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro + t*rd;
        float h = map( pos ).x;
        res = min( res, 16.0*h/t );
        if ( res<0.001 ) break;
        t += h;
        if( t > 10.0 ) break;
    }

    return clamp(res,0.0,1.0);
} 

vec2 castRay( in vec3 ro, vec3 rd )
{
    float m = -1.0;
    float t = 0.0;
    float d = 20.;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro + t*rd;

        vec2 h = map( pos );
        m = h.y;
        if( h.x<0.001 )
            break;
        t += h.x;
        if( t>d )
            break;
    } 
    if( t>d ) m=-1.0;
    return vec2(t,m);
}

#define AA 3.

void main() {
    float time = iTime;
    vec3 res = vec3(0);
    
    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y; 
        
        float pause = 0.075;
        float angle = 3.14 * ( smoothstep(0.0+pause, 0.25-pause, fract(iTime/12.)) +
                               smoothstep(0.5+pause, 0.75-pause, fract(iTime/12.)) ) + 3.14/2. + 3.14/10.;
               
        mat3 rot = rotateY(-angle);

        vec3 ro = vec3(0.0,3. + 2.*(iMouse.y/iResolution.y)-1. ,4.0) * rot;
        vec3 ta = vec3(0,-2.0,-1) * rot;   

        ro += ta;
        
        vec3 ww = normalize( ta-ro );
        vec3 uu = normalize( cross(ww, vec3(0,1,0)) );
        vec3 vv = normalize( cross(uu,ww) );

        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );

        vec3 col = vec3(0.4,0.75,1.0) - 0.5*rd.y;
        col = mix( col, vec3(0.7,0.75,0.8), exp(-10.0*rd.y) );

        vec2 tm = castRay(ro, rd);

        if( tm.y>0.0 )
        {
            float t = tm.x;
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);

            vec3 mate = vec3(0.18);

            if( tm.y < 1.5 )
            {
                vec2 checker = trunc(fract(circleFold(pos.xz,4.,0.5))*4.);
                float cm = (mod(checker.x + checker.y, 2.0) == 0.0) ? 1. : 0.;
                mate = vec3(0.3) * cm;
            }
            else if( tm.y < 2.5 )
            {
                mate = vec3(0.2);
            }
            else if( tm.y < 3.5);
            {
                //mate = vec3(0.1,0,0);
            }

            vec3 sun_dir = normalize( vec3(0.5,0.2,-0.35) );
            float sun_dif = clamp( dot(nor,sun_dir),0.0,1.0);
            float sun_sha = castShadow( pos+nor*0.02, sun_dir );
            float sky_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0);
            float bou_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

            col  = mate*vec3(7.0,4.5,3.0)*sun_dif*sun_sha;
            col += mate*vec3(0.5,0.8,0.9)*sky_dif;
            col += mate*vec3(0.7,0.3,0.2)*bou_dif;
            res += clamp(col, 0.0, 1.0);
        }
    }

    res = pow( res / (AA * AA), vec3(0.4545) );
    
    O = vec4(res, 1.0);
}
