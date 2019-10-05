// Tutorial from https://www.youtube.com/watch?v=Cfe5UQ-1L9Q
// Thanks iq!
// Shadertoy defines

#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime

#define R iResolution.xy

float sdSphere( in vec3 pos, float rad )
{
    return length(pos) - rad;
}

float sdStick( in vec3 p, vec3 a, vec3 b, float ra, float rb )
{
    vec3 ba = b-a;
    vec3 pa = p-a;

    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0);

    float r = mix(  ra, rb, h );
    return length(pa-h*ba) - r;
}

float sdElipsoid( in vec3 pos, vec3 rad )
{
    float k0 = length(pos/rad);
    float k1 = length(pos/rad/rad);
    return k0*(k0-1.0)/k1;
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

vec2 sdGuy( in vec3 pos )
{
    float t = fract(iTime);
    float y = 4.0*t*(1.0-t);
    float dy = 4.0*(1.0-2.0*t);

    vec2 u =  normalize(vec2( 1.0, -dy ));
    vec2 v = vec2( dy, 1.0 );

    vec3 cen = vec3(0.0,y,0.0);

    float sy = 0.5 + 0.5*y;
    float sz = 1.0/sy;
    

    vec3 rad = vec3(0.25,0.25*sy,0.25*sz);

    vec3 q = pos-cen;
    //q.yz = vec2( dot(u,q.yz), dot(v,q.yz) );

    float d = sdElipsoid(q,rad);

    vec3 h = q;
    vec3 sh = vec3( abs(h.x), h.yz );

    // head
    float d2 = sdElipsoid(h - vec3(0.0,0.28,0.0),vec3(0.15,0.2,0.23));
    float d3 = sdElipsoid(h - vec3(0.0,0.28,-0.1),vec3(0.23,0.2,0.2));
    d2 = smin(d2,d3,0.05);
    d = smin(d, d2, 0.1);

    // eyebrows
    vec3 eb = sh-vec3(0.12,0.34,0.15);
    eb.xy = (mat2(3,4,-4,3)/5.0)*eb.xy;
    d2 = sdElipsoid(eb,vec3(0.06,0.035,0.05));
    d = smin(d, d2, 0.04);

    // mouth
    d2 = sdElipsoid(h-vec3(0.0,0.15 + 3.*h.x*h.x,0.15),vec3(0.1,0.035,.2));
    d = smax(d,-d2,0.03);

    // ears
    d2 = sdStick( sh, vec3(0.1, 0.4, -0.01), vec3(0.2,0.55,0.02),0.01,0.03);
    d = smin(d,d2,0.03);

    vec2 res = vec2(d,2.0);

    // eye
    float d4 = sdSphere( sh - vec3(0.08,0.28,0.16), 0.05 );
    if( d4<d ) res = vec2(d4, 3.0);

    d4 = sdSphere(sh - vec3(0.09,0.28,0.18), 0.02);
    if( d4<d ) res = vec2(d4, 4.0);

    d = min(d,d4);

    return res;
}

vec2 map( in vec3 pos ) 
{
    float cr = 0.10;
    vec2 d1 = sdGuy(pos);

    float d2 = pos.y - (-0.25);

    return (d2<d1.x) ? vec2(d2,1.0) : d1;
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
    float t = 0.001;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro + t*rd;
        float h = map( pos ).x;
        res = min( res, 16.0*h/t );
        if ( res<0.0001 ) break;
        t += h;
        if( t > 20.0 ) break;
    }

    return clamp(res,0.0,1.0);
} 

vec2 castRay( in vec3 ro, vec3 rd )
{
    float m = -1.0;
    float t = 0.0;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro + t*rd;

        vec2 h = map( pos );
        m = h.y;
        if( h.x<0.0001 )
            break;
        t += h.x;
        if( t>20.0 )
            break;
    } 
    if( t>20.0 ) m=-1.0;
    return vec2(t,m);
}

void main() {
    float time = iTime;
    
    vec2 p = (2.*U-R)/R.y;
    float an = 10.0*iMouse.x/iResolution.x;
    
    vec3 ta = vec3(0.0,0.5,1.0);
    vec3 ro = ta + vec3(1.5*sin(an),0.0,1.5*cos(an));
    

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
            mate = vec3(0.05,0.1,0.02);
        }
        else if( tm.y<2.5 )
        {
            mate = vec3(0.2,0.1,0.02);
        }
        else if( tm.y<3.5 )
        {
            mate = vec3(0.9);
        }
        else if( tm.y<4.5 )
        {
            mate = vec3(0.02);
        }

        vec3 sun_dir = normalize( vec3(0.8,0.4,0.2) );
        float sun_dif = clamp( dot(nor,sun_dir),0.0,1.0);
        float sun_sha = castShadow( pos+nor*0.001, sun_dir );
        float sky_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0);
        float bou_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

        col  = mate*vec3(7.0,4.5,3.0)*sun_dif*sun_sha;
        col += mate*vec3(0.5,0.8,0.9)*sky_dif;
        col += mate*vec3(0.7,0.3,0.2)*bou_dif;

    }

    col = pow( col, vec3(0.4545) );
    
    O = vec4(col, 1.0);
}
