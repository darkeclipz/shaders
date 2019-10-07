# Basic Raymarcher

## castRay

Let _ro_ be the **ray origin**, and _rd_ be the **ray direction**. We start with taking _t_ steps (at 0.00) into the ray direction (into the scene). 

![ray](https://github.com/darkeclipz/shaders/blob/master/screenshots/ray.png)

Then we advance _t_ with the distance to the closest object, which is determined from the `map` function. Once the distance to the closest object is less than, e.g. 0.001, we have hit the object.

```glsl
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
```

## calcNormal

The function `calcNormal` calculates the normal vector on a surface for a point. The normal is used for a lot of lightning calculations.

![normal](https://github.com/darkeclipz/shaders/blob/master/screenshots/normal.png)

The normal vector represents the vector that is normal to the surface, e.g. perpendicular/orthogonal.

```glsl
vec3 calcNormal( in vec3 pos ) 
{
    vec2 e = vec2(NormalPrecision, 0.0);
    return normalize( vec3(map(pos+e.xyy).x-map(pos-e.xyy).x,
                           map(pos+e.yxy).x-map(pos-e.yxy).x,
                           map(pos+e.yyx).x-map(pos-e.yyx).x ) );
}
```

## map

The function `map` combines all the signed distance fields (SDF's) and determines the object id. Multiple distance fields, such as for primitive shapes (or fractals), can be combined with `min(sdf1, sdf2)`. In essence, the scene is put together in the `map` function.

```glsl
vec2 map( in vec3 pos ) 
{
    float id = 1.0;
    float d = sdBox( pos - vec3(0,-0.7,0), 0.5*normalize(vec3(1,1,1)) ); // Box
    float d2 = pos.y + 1.0; // Plane
    if( d2 < d ) id = 2.0;
    d = min(d, d2);
    return vec2(d, id);
}
```

## sdBox

The function `sdBox` is used to create a box. The position of the box is `vec3 p` and the bounds (w/l/h) is `vec3 b`. Iniqo Quilez has a list of [distance field functions for primitives](https://iquilezles.org/www/articles/distfunctions/distfunctions.htm).

![sdBox](https://github.com/darkeclipz/shaders/blob/master/screenshots/sdbox.PNG)

```glsl
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
}
```

## castShadow

The function `castShadow` uses the same raymarching technique as the `castRay` function. Instead of from the camera, we now shoot a ray from our found point in the scene, into the direction of the sun (light source). If this ray hits something, an object in the scene, we know that there is an object in the way between the light source and the point on the surface. Because we can also track how close we got to the closest object, we use this distance to create soft shadows.

```glsl
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
```

## main

In the `main` function everything comes together. To render an image we take the following steps:

 * Aliasing loop, supersampling the scene.
 * Get pixel coordinates `uv`.
 * Set up of the camera.
 * Determine the ray.
 * Determine the sky color (if we miss).
 * Cast a ray into the scene.
 * Determine if it was a hit.
 * Select the proper material id.
 * Calculate and apply the lightning.
 * Gamma correction.

```glsl
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

# Full Code

The complete raymarcher is in the code below.

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