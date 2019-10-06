#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime

#define R iResolution.xy
#define MaxSteps 60
#define MinRayDistance 0.0001
#define MaxRayDistance 20.
#define MinShadowRayDistance 0.001
#define MaxShadowRayDistance 20.
#define NormalPrecision 0.001

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

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
}

float sdPlane(in vec3 p, in vec4 n)
{
  return dot(p,n.xyz) + n.w;
}

float sdSphere(vec3 p, float r) 
{
	return length(p) - r;    
} 

float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float sdCapsule(vec3 p,  vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;

    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0., 1.);

    vec3 c = a + t * ab;
    float d = length(p-c) - r;
    return d;
}

vec2 sdTemple( in vec3 p )
{
    

    // 4 fold symmetry
    vec3 ps = vec3(abs(p.xz), p.y).xzy;

    // floor
    float d = sdBox( ps - vec3(1,-1,1), vec3(1, 0.02, 1) );
    float id = 2.;
    float d2 = sdBox( ps - vec3(0.95,-0.98, 0.95), vec3(0.95, 0.02, 0.95) );
    if(d2<d) id = 3.;
    d = min(d, d2);

    //base 
    d2 = sdBox( p - vec3(0.4,-0.6, 0.4), vec3(0.95, 0.4, 0.95) );

    //if(d2 < d) id = 4.;
    //d = min(d, d2);

    
    for(float i=0.3; i <= 1.9; i += 0.2)
    {
        d2 = sdBox( ps - vec3(i, -0.6, 1.7), vec3(0.03, 0.4, 0.03) );
        if(d2 < d) id = 6.;
        d = min(d, d2);
        
        d2 = sdBox( ps - vec3(i, -0.95, 1.7), vec3(0.04, 0.04, 0.04) );
        if(d2 < d) id = 6.;
        d = min(d, d2);
        
        d2 = sdBox( ps - vec3(i, -0.975, 1.7), vec3(0.05, 0.05, 0.05) );
        if(d2 < d) id = 6.;
        d = min(d, d2);

    
        d2 = sdBox( ps - vec3(1.7, -0.6, i), vec3(0.03, 0.4, 0.03) );
        if(d2 < d) id =6.;
        d = min(d, d2);

        d2 = sdBox( ps - vec3(1.7, -0.95, i), vec3(0.04, 0.04, 0.04) );
        if(d2 < d) id = 6.;
        d = min(d, d2);

        d2 = sdBox( ps - vec3(1.7, -0.975, i), vec3(0.05, 0.05, 0.05) );
        if(d2 < d) id = 6.;
        d = min(d, d2);
    }
    
    
    // roof start
    d2 = sdBox( ps - vec3(0.8,-0.16, 0.8), vec3(0.95, 0.04, 0.95) );
    if(d2< d) id = 7.;
    d = min(d, d2);

    d2 = sdBox( ps - vec3(0.8,-0.13, 0.8), vec3(0.90, 0.04, 0.90) );
    if(d2 < d) id = 8.;
    d = min(d, d2);

    // roof
    //d2 = sdTriPrism(p * vec3(0.15,1,1) - vec3(0,0.031,0), vec2(0.3,1.72));
    //d = min(d, d2);

    return vec2(d, id);
}


vec2 map( in vec3 pos ) 
{
    vec2 dsTemple = sdTemple(pos);
    float id = dsTemple.y;
    float d = dsTemple.x;
    float d2 = pos.y + 1.0; // Plane
    if( d2 < d ) id = 1.0;
    d = min(d, d2); 
    
    return vec2(d, id);
}

vec3 calcNormal( in vec3 pos ) 
{
    vec2 e = vec2(NormalPrecision, 0.0);
    return normalize( vec3(map(pos+e.xyy).x-map(pos-e.xyy).x,
                           map(pos+e.yxy).x-map(pos-e.yxy).x,
                           map(pos+e.yyx).x-map(pos-e.yyx).x ) );
}

float castShadow( in vec3 ro, vec3 rd )
{
    float res = 1.0;
    float t = 0.0;
    for( int i=0; i<MaxSteps; i++ )
    {
        vec3 pos = ro + t*rd;
        float h = map( pos ).x;
        res = min( res, 16.0*h/t );
        if ( res<MinShadowRayDistance ) break;
        t += h;
        if( t > MaxShadowRayDistance ) break;
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
        if( h.x<MinRayDistance )
            break;
        t += h.x;
        if( t>MaxRayDistance )
            break;
    } 
    if( t>MaxRayDistance ) m=-1.0;
    return vec2(t,m);
}

#define AA 2.

void main() {
    float time = iTime;
    vec3 res = vec3(0);

    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y; 
        
        mat3 rot = rotateY(iTime/32.);
        
        vec3 ro = vec3(0,0.2,1.0);
        vec3 ta = vec3(0,0.2,0.0); 
        ro += ta;  

        ro *= rot;
        ta *= rot;
   
        vec3 forward = vec3(0,-0.75,1.6) * rot;
        vec3 translation = 0.*vec3(0,2.1,1);
        ro += forward + translation;
        ta += forward + translation;
        
        // Set up camera
        vec3 ww = normalize( ta-ro );
        vec3 uu = normalize( cross(ww, vec3(0,1,0)) );
        vec3 vv = normalize( cross(uu,ww) );

        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );

        // Sky color.
        vec3 col = vec3(1);
        col = mix( col, vec3(0.7,0.75,0.8), exp(-10.0*rd.y) );

        vec2 tm = castRay(ro, rd);

        if( tm.y>0.0 )
        {
            // Calculate position and normal.
            float t = tm.x;
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);

            vec3 mate = vec3(0.22);
        
            // Select material color.
            if( tm.y < 1.5 ) {
                //vec2 checker = trunc(fract(pos.xz)*4.);
                //float cm = (mod(checker.x + checker.y, 2.0) == 0.0) ? 1. : 0.;
                mate = vec3(0.075);
                
            }   
            else if( tm.y < 2.5 )
            {
                
            }
            else if( tm.y < 3.5 ) 
            {
                vec2 checker = trunc(fract(pos.xz)*6.);
                float cm = (mod(checker.x + checker.y, 2.0) == 0.0) ? 1. : 0.;
                
                float floorSize = 0.166667*9.;
                if(abs(pos).x < floorSize && abs(pos).z < floorSize) {
                    mate = (vec3(0.025) * cm + vec3(0.15) * (1.-cm));                

                    if(cm < 0.01) 
                    {
                        nor.y += 0.01;
                    }
                }
                    
            }
            else if( tm.y < 4.5 )  {}
            else if( tm.y < 5.5 )  {}
            else if( tm.y < 6.5 )  {}
            else if( tm.y < 7.5 )  {}
            else if( tm. y < 8.5)
            {
                mate = vec3(0.45,0.03,0);

                vec2 checker = trunc(fract(pos.xz)*12.);
                float cm = (mod(checker.x + checker.y, 2.0) == 0.0) ? 1. : 0.;

                mate += 0.0075 * cm;
            }


            // Calculating lightning.
            float sunAngle = iTime;
            mat3 rotSun = rotateY(sunAngle/32. + 3.14/4.);
            vec3 sun_dir = normalize( vec3(0.05,0.03,0.05)*rotSun );
            float sun_dif = clamp( dot(nor,sun_dir),0.0,1.0);
            float sun_sha = castShadow( pos+nor*0.02, sun_dir );
            float sky_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0);
            float bou_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

            // Applying lightning.
            col  = mate*vec3(7.0,4.5,3.0)*sun_dif*sun_sha;
            col += mate*vec3(0.5,0.8,0.9)*sky_dif;
            col += mate*vec3(0.4)*bou_dif;
        }

        res += clamp(col, 0.0, 1.0);
    }

    // Gamma correction
    res = pow( res / (AA * AA), vec3(0.4545) );
    
    O = vec4(res, 1.0);
}
