// Shadertoy defines
#define O gl_FragColor
#define U gl_FragCoord.xy
#define iGlobalTime iTime

#define R iResolution.xy

void main() {
    float time = iTime;
    vec2 uv = (2.*U-R)/R.y;
    vec3 col = vec3(0);
    
    O = vec4(col, 1.0);
}
