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

// vec2 getOffset(float time) 
// {
//     float frames = 5.;
//     time = mod(time, frames);

//     float it = floor(time),
//           ft = fract(time);
    
//     vec2 p1 = vec2(-3.2, -2.4);
//     vec2 p2 = vec2(-3.4, -4.1); 
//     vec2 p3 = vec2(-2.2, -3.3); 
//     vec2 p4 = vec2(-3.8, -3.7); 
//     vec2 pl = vec2(0.85, -2.3);
 
//     vec2 pos = p1;
 
//     if(it < 0.5)       pos = mix(pl, p1, smoothstep(0.0, 1.0, ft));
//     else if(it < 1.5)  pos = mix(p1, p2, smoothstep(0.0, 1.0, ft));
//     else if(it < 2.5)  pos = mix(p2, p3, smoothstep(0.0, 1.0, ft));
//     else if(it < 3.5)  pos = mix(p3, p4, smoothstep(0.0, 1.0, ft));
//     else if(it < 4.5)  pos = mix(p4, pl, smoothstep(0.0, 1.0, ft));

//     return pos;
// }

vec2 DE(vec3 z, float time)
{
    //float angl = sin(time) * 0.3;//(iMouse.x/iResolution.y);//cos(time) * .2 + .6;
    float angl = (0.5*sin(time)+0.5) * 4. - 2.;
    mat3 rx = rotateX(angl);
    mat3 ry = rotateY(angl);
    mat3 rz = rotateZ(angl);
    mat3 rot = rx * ry * rz;
 
    //float Scale = sin(5.*time)*0.25 + 2.2;//cos(time) * .2 + 1.6;
    float Scale = (iMouse.y/iResolution.y) * 4. - 2.;
    float Offset = .6;
    float n = 0.;
    float trap = 10.;
    float dr = 1.;
    while (n < 60.) {
       z = abs(z);
       if(z.x - z.y < 0.) z.xy = z.yx;
       if(z.x - z.z < 0.) z.xz = z.zx;
       if(z.y - z.z < 0.) z.yz = z.zy;

       z = boxFold(z, vec3(1));
       z = mengerFold(z);
       z *= rot;
       z = abs(z);
       
       dr = dr*abs(Scale)+1.0;
       z = z*Scale - vec3(vec3(Offset*(Scale-1.0)).xy, 0);
       trap = min(trap, length(z));
       n++;
    }
    return vec2((length(z) ) * pow(Scale, -float(n)), trap);
}


vec2 map( in vec3 pos, float time )  
{
    vec2 d1 = DE(pos, time);
    return d1;
}

vec3 calcNormal( in vec3 pos, float t ) 
{
    vec2 e = vec2(0.00001, 0.0);
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
        if( h.x<0.00095 )
            break;
        t += h.x;
        if( t>40.0 )
            break;
    } 
    if( t>40.0 ) m=-1.0;
    return vec2(t,m);
}
 
void main() {

    float time = iTime;
    time /= 60.;

    vec3 col = vec3(0);
    vec3 res = vec3(0);
    
    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y;
        
        mat3 rot =    rotateY(sin(time)*0.5) 
                    * rotateZ(sin(time)*0.5);
        vec3 ta = vec3(0,0,1)*rot;
        vec3 ro = vec3(0,0,-12.2)*rot;
        
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

            vec3 mate = vec3(0.18); 
            mate = cos(vec3(0,1,1.5) + tm.y*6. - time*11.) *.5 + .5;

            mat3 sunRot = rotateY(1.9);
            vec3 sun_dir = normalize( vec3(-5,0.05,-2) * sunRot );
            float sun_dif = clamp( dot(nor,sun_dir),0.0,1.0); 
            float sun_sha =castShadow( pos+nor*0.001, sun_dir, time );
            float sky_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0);
            float bou_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

            col  = 0.25*mate*vec3(5.0,4.5,4.0)*sun_dif*sun_sha;
            //col += mate*vec3(0.5,0.6,0.6)*sky_dif;
            col += 0.2*mate*vec3(1.5,0.6,0.6)*bou_dif;
        }

        res += clamp(col, 0.0, 1.0);
    }

    col = pow( res/(AA*AA), vec3(0.4545) );
    
    O = vec4(col, 1.0);
}
