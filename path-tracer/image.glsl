#iChannel0 './path-tracer/path-tracer.glsl'
#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime 
#define R iResolution.xy 

void main() 
{
	vec2 uv = U.xy / R.xy;  

    vec3 col = vec3(0.0);
    
    if( iFrame>0 )
    {
        col = texture( iChannel0, uv ).xyz;
        col /= float(iFrame);
        col = pow( col, vec3(0.4545) );
        //col = vec3(1,0,0);
    }
    
    // color grading and vigneting
    col = pow( col, vec3(0.8,0.85,0.9) );
    
    col *= 0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.1 );
    
    O = vec4( col, 1.0 );
}