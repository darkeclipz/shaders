// Modified version of https://www.shadertoy.com/view/MsdGzl


// Created by inigo quilez - iq/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

// Pathtrace the scene. One path per pixel. Samples the sun light and the
// sky dome light at each vertex of the path.

// More info here: http://iquilezles.org/www/articles/simplepathtracing/simplepathtracing.htm


//------------------------------------------------------------------
#iChannel0 "self" 
float hash(float seed)
{
    return fract(sin(seed)*43758.5453 );
}

vec3 cosineDirection( in float seed, in vec3 nor)
{
    float u = hash( 78.233 + seed);
    float v = hash( 10.873 + seed);

    
    // Method 1 and 2 first generate a frame of reference to use with an arbitrary
    // distribution, cosine in this case. Method 3 (invented by fizzer) specializes 
    // the whole math to the cosine distribution and simplfies the result to a more 
    // compact version that does not depend on a full frame of reference.

    #if 0
        // method 1 by http://orbit.dtu.dk/fedora/objects/orbit:113874/datastreams/file_75b66578-222e-4c7d-abdf-f7e255100209/content
        vec3 tc = vec3( 1.0+nor.z-nor.xy*nor.xy, -nor.x*nor.y)/(1.0+nor.z);
        vec3 uu = vec3( tc.x, tc.z, -nor.x );
        vec3 vv = vec3( tc.z, tc.y, -nor.y );

        float a = 6.2831853 * v;
        return sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
    #endif
	#if 1
    	// method 2 by pixar:  http://jcgt.org/published/0006/01/01/paper.pdf
    	float ks = (nor.z>=0.0)?1.0:-1.0;     //do not use sign(nor.z), it can produce 0.0
        float ka = 1.0 / (1.0 + abs(nor.z));
        float kb = -ks * nor.x * nor.y * ka;
        vec3 uu = vec3(1.0 - nor.x * nor.x * ka, ks*kb, -ks*nor.x);
        vec3 vv = vec3(kb, ks - nor.y * nor.y * ka * ks, -nor.y);
    
        float a = 6.2831853 * v;
        return sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
    #endif
    #if 0
    	// method 3 by fizzer: http://www.amietia.com/lambertnotangent.html
        float a = 6.2831853 * v;
        u = 2.0*u - 1.0;
        return normalize( nor + vec3(sqrt(1.0-u*u) * vec2(cos(a), sin(a)), u) );
    #endif
}

//------------------------------------------------------------------

float maxcomp(in vec3 p ) { return max(p.x,max(p.y,p.z));}

float sdBox( vec3 p, vec3 b )
{
  vec3  di = abs(p) - b;
  float mc = maxcomp(di);
  return min(mc,length(max(di,0.0)));
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

// http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/
vec2 DE(vec3 pos, float time) {
        
    pos *= rotateX(3.14/2.) * rotateZ(time);

    float Iterations = 12.;
    float Bailout = 2.;
    float Power = 12.;
    
    vec3 trap = vec3(0,0,0);
    float minTrap = 1e10;
    
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (float i = 0.; i < Iterations ; i++) {
		r = length(z);
		if (r>Bailout) break;
        
        minTrap = min(minTrap, z.z);
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;
		
		// convert back to cartesian coordinates
		//z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z = zr*vec3( cos(theta)*cos(phi), cos(theta)*sin(phi), sin(theta) );
		z+=pos;
	}
	return vec2(0.5*log(r)*r/dr, minTrap);
}

vec2 map( vec3 p )
{
    return DE(p, 1.);
}

//------------------------------------------------------------------

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3(0.00005,0.0,0.0);

    return normalize( vec3(
      map( pos+eps.xyy ).x - map( pos-eps.xyy ).x,
      map( pos+eps.yxy ).x - map( pos-eps.yxy ).x,
      map( pos+eps.yyx ).x - map( pos-eps.yyx ).x ) );
}


vec2 intersect( in vec3 ro, in vec3 rd )
{
    float res = -1.0;
    float tmax = 16.0;
    float t = 0.01;
    float orbit = 1e10;
    for(int i=0; i<80; i++ )
    {
        vec2 h = map(ro+rd*t);
        if( h.x<0.00001 || t>tmax ) break;
        t +=  h.x;
        orbit = h.y;
    }
    
    if( t<tmax ) res = t;

    return vec2(res, orbit);
}

float shadow( in vec3 ro, in vec3 rd )
{
    float res = 0.0;
    
    float tmax = 20.0;
    
    float t = 0.001;
    for(int i=0; i<80; i++ )
    {
        float h = map(ro+rd*t).x;
        if( h<0.0001 || t>tmax) break;
        t += h;
    }

    if( t>tmax ) res = 1.0;
    
    return res;
}

vec3 sunDir = normalize(vec3(-5,4,4));
vec3 sunCol =  6.0*vec3(1.0,0.5,0.6);
vec3 skyCol =  4.0*vec3(0.2,0.35,0.5);

vec3 calculateColor(vec3 ro, vec3 rd, float sa )
{
    const float epsilon = 0.0001;

    vec3 colorMask = vec3(1.0);
    vec3 accumulatedColor = vec3(0.0);

    float fdis = 0.0;
    for( int bounce = 0; bounce<3; bounce++ ) // bounces of GI
    {
        //rd = normalize(rd);
       
        //-----------------------
        // trace
        //-----------------------
        vec2 tm = intersect( ro, rd );
        float t = tm.x;
        if( t < 0.0 )
        {
            if( bounce==0 ) return vec3(1);
            break;
        }

        if( bounce==0 ) fdis = t;

        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal( pos );

        vec3 mate = cos(vec3(0,2,4) + 2.*tm.y + 5.) *.5 + .5;
        vec3 surfaceColor = mate;//vec3(0.4)*vec3(1,0,0);

        //-----------------------
        // add direct lighting
        //-----------------------
        colorMask *= surfaceColor;

        vec3 iColor = vec3(0.0);
		sunDir = normalize(ro + vec3(-1,1.2,2));
        // light 1        
        float sunDif =  max(0.0, dot(sunDir * rotateY(1.9), nor));
        float sunSha = 1.0; if( sunDif > 0.00001 ) sunSha = shadow( pos + nor*epsilon, sunDir);
        iColor += sunCol * sunDif * sunSha;
        // todo - add back direct specular

        // light 2
        vec3 skyPoint = cosineDirection( sa + 7.1*float(iFrame) + 5681.123 + float(bounce)*92.13, nor);
        float skySha = shadow( pos + nor*epsilon, skyPoint);
        iColor += skyCol * skySha;


        accumulatedColor += colorMask * iColor;

        //-----------------------
        // calculate new ray
        //-----------------------
        //float isDif = 0.8;
        //if( hash(sa + 1.123 + 7.7*float(bounce)) < isDif )
        {
           rd = cosineDirection(76.2 + 73.1*float(bounce) + sa + 17.7*float(iFrame), nor);
        }
        //else
        {
        //    float glossiness = 0.2;
        //    rd = normalize(reflect(rd, nor)) + uniformVector(sa + 111.123 + 65.2*float(bounce)) * glossiness;
        }

        ro = pos;
   }

   float ff = exp(-0.01*fdis*fdis);
   accumulatedColor *= ff; 
   accumulatedColor += (1.0-ff)*0.05*vec3(0.9,1.0,1.0);

   return accumulatedColor;
}

mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
	vec3 cw = normalize(rt-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}

#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime
#define R iResolution.xy

void main()
{
    float sa = hash( dot( U, vec2(12.9898, 78.233) ) + 1113.1*float(iFrame) );
    
    vec2 of = -0.5 + vec2( hash(sa+13.271), hash(sa+63.216) );
    vec2 p = (-R.xy + 2.0*(U+of)) / R.y;

	vec3 ta = vec3(0,-1.,1);
    vec3 ro = vec3(0,1.2,-1.3);
    //vec3 ta = vec3(1,0,0);
    //vec3 ro = vec3(0.5,0.5,1) + ta;

    mat3  ca = setCamera( ro, ta, 0.0 );
    vec3  rd = normalize( ca * vec3(p,-1.3) );

    vec3 col = texture( iChannel0, U/R.xy ).xyz;
    if( iFrame==0 ) col = vec3(0.0);
    
    col += calculateColor( ro, rd, sa );

    O = vec4( col, 1.0 );
}