# Basic Raymarcher

## sdBox

The function `sdBox` is used to create a box. The position of the box is `vec3 p` and the bounds (w/l/h) is `vec3 b`.

[sdBox](https://github.com/darkeclipz/shaders/blob/master/screenshots/sdbox.PNG)

```glsl
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
}
```

## map

```glsl

```

## calcNormal

```glsl

```

## castShadow

```glsl

```

## castRay

```glsl

```

## main

```glsl

```

# Full Code


```glsl
#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime

#define R iResolution.xy
#define MaxSteps 100
#define MinRayDistance 0.001
#define MaxRayDistance 10.
#define MinShadowRayDistance 0.01
#define MaxShadowRayDistance 10.
#define NormalPrecision 0.0001

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
}

vec2 map( in vec3 pos ) 
{
    float id = 1.0;
    float d = sdBox( pos - vec3(0,-0.7,0), 0.5*normalize(vec3(1,1,1)) ); // Box
    float d2 = pos.y + 1.0; // Plane
    if( d2 < d ) id = 2.0;
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
    float t = 0.01;
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

#define AA 3.

void main() {
    float time = iTime;
    vec3 res = vec3(0);

    for(float aax=0.; aax < AA; aax++)
    for(float aay=0.; aay < AA; aay++)
    {
        vec2 p = (2.*(U + vec2(aax, aay) / AA)-R)/R.y; 
        
        vec3 ro = vec3(0.0,3.8,4.5);
        vec3 ta = vec3(0,-3.,-2);   

        ro += ta;
        
        // Set up camera
        vec3 ww = normalize( ta-ro );
        vec3 uu = normalize( cross(ww, vec3(0,1,0)) );
        vec3 vv = normalize( cross(uu,ww) );

        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );

        // Sky color.
        vec3 col = vec3(0.4,0.75,1.0) - 0.5*rd.y;
        col = mix( col, vec3(0.7,0.75,0.8), exp(-10.0*rd.y) );

        vec2 tm = castRay(ro, rd);

        if( tm.y>0.0 )
        {
            // Calculate position and normal.
            float t = tm.x;
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);

            vec3 mate = vec3(0.18);

            // Select material color.
            if( tm.y < 1.5 )      mate = vec3(0.2);
            else if( tm.y < 2.5 ) mate = vec3(0.1);

            // Calculating lightning.
            vec3 sun_dir = normalize( vec3(-0.5,0.2,-0.25) );
            float sun_dif = clamp( dot(nor,sun_dir),0.0,1.0);
            float sun_sha = castShadow( pos+nor*0.02, sun_dir );
            float sky_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0);
            float bou_dif = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

            // Applying lightning.
            col  = mate*vec3(7.0,4.5,3.0)*sun_dif*sun_sha;
            col += mate*vec3(0.5,0.8,0.9)*sky_dif;
            col += mate*vec3(0.7,0.3,0.2)*bou_dif;
            res += clamp(col, 0.0, 1.0);
        }
    }

    // Gamma correction
    res = pow( res / (AA * AA), vec3(0.4545) );
    
    O = vec4(res, 1.0);
}

```