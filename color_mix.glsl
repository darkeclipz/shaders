// Shadertoy defines
#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime

#define R iResolution.xy

vec3 color(float t) 
{
    t = fract(t);
    vec3 color1 = vec3(1.0,0.55,0.0);
    vec3 color2 = vec3(0.7);
    return mix(color1, color2, smoothstep(0.0, 0.12, abs(t-0.5)));
}

void main() {
    float time = iTime;
    vec2 uv = U/R.y;
    vec3 col = color(uv.x);
    
    O = vec4(col, 1.0);
}
