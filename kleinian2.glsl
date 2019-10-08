// Tutorial from https://www.youtube.com/watch?v=Cfe5UQ-1L9Q
// Thanks iq!
// Shadertoy defines

#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime
#define AA 1.
#define R iResolution.xy

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

const vec4 param_min = vec4(-0.8323, -0.694, -0.5045, 0.8067);
const vec4 param_max = vec4(0.8579, 1.0883, 0.8937, 0.9411);
vec2 DE(vec3 p, float s)
{
    float k1, k2, rp2, rq2;
    float scale = 1.0;
    float orb = 1e4;
    vec3 q = p;
    for (int i = 0; i < 10; i++)
	{
        p = 2.0 * clamp(p, param_min.xyz, param_max.xyz) - p;
	    q = 2.0 * fract(0.5 * q + 0.5) - 1.0;
	    rp2 = dot(p, p);
        rq2 = dot(q, q);
	    k1 = max(param_min.w / rp2, 1.0);
        k2 = max(param_min.w / rq2, 1.0);
	    p *= k1;
        q *= k2;
	    scale *= k1;
        orb = min(orb, rq2);
	}
    float lxy = length(p.xy);
    return vec2(0.5 * max(param_max.w - lxy, lxy * p.z / length(p)) / scale,
                0.25 + sqrt(orb));
}


vec2 map( in vec3 pos, float time )  
{
    vec2 d1 = DE(pos, time);
    return d1;
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
    for( int i=0; i< 200; i++ )
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
    float t = 0.01;
    for( int i=0; i<200; i++ )
    {
        float precis = 0.0001 * t;
        vec3 pos = ro + t*rd;

        vec2 h = map( pos, time );
        m = h.y;
        if( h.x<precis )
            break;
        t += h.x;
        if( t>20.0 )
            break;
    } 
    if( t>20.0 ) m=-1.0;
    return vec2(t,m);
}

vec3 color(float t) 
{
    vec3 color1 = vec3(50) / 255.;
    vec3 color2 = vec3(210) / 255.;
    return mix(color1, color2, smoothstep(0.0, 0.75, abs(t-0.5)));
}

void main() {

    float time = iTime;

    time /= 20.;

    vec3 col = vec3(0);
    vec3 res = vec3(0);
    
    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y;
        
        mat3 rot = rotateY(time) * rotateZ(13.*time) ;

        vec3 ta = vec3(1.5,0.1,-5.4);
        float lj = 2.2;
        vec3 ro = vec3(0.5,0.5,1) + ta;
        
        vec3 ww = normalize( ta-ro );
        vec3 uu = normalize( cross(ww, vec3(0,1,0)) );
        vec3 vv = normalize( cross(uu,ww) );

        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );
 
        vec3 col = vec3(0.0);

        vec2 tm = castRay(ro, rd, time); 

        if( tm.x < 20. )
        {
            float t = tm.x;
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos, time);

            

            //mate = vec3(0.7);


            vec3  light1 = vec3( vec3(0.5) );
            vec3  light2 = vec3( vec3(1,0.75,-.15) );

            float key = clamp( dot( light1, nor ), 0.0, 1.0 );
            float bac = clamp( 0.2 + 0.8*dot( light2, nor ), 0.0, 1.0 );
            float amb = (0.7+0.3*nor.y);
            float ao = pow( clamp(tm.y*2.0,0.0,1.0), 1.2 );

            vec3 mate = cos(vec3(0,2,4) + 4.*tm.y + 4.*iMouse.x/iMouse.y); 
            mate = 0.5 + 0.5 * cos(2.0 * 3.1415 * 2.0 * tm.y + vec3(0.0, 1.0, 2.0) + 4.*iMouse.x/iMouse.y);

            vec3 brdf  = 1.0*vec3(0.40,0.40,0.40)*amb*ao;
            brdf += 1.0*vec3(1.00,1.00,1.00)*key*ao;
            brdf += 1.0*vec3(0.40,0.40,0.40)*bac*ao;

            col = mate * brdf * exp(-0.2*t);
        }

        res += clamp(col, 0.0, 1.0);
    }

    col = pow( res/(AA*AA), vec3(0.4545) );
    
    O = vec4(col, 1.0);
}
