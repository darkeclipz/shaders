#define R iResolution.xy
#define MAX_STEPS 100
#define MAX_DIST 300.
#define SURF_DIST .01


float sdCapsule(vec3 p,  vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;

    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0., 1.);

    vec3 c = a + t * ab;
    float d = length(p-c) - r;
    return d;
}

float sdSphere(vec3 p, vec3 a, float r) {
    return length(p-a) - r;
}


float GetDist(vec3 p) {
    vec4 s = vec4(0, 1, 6, 1);

    float sphereDist = length(p-s.xyz) - s.w;
    float planeDist = p.y;
    float capsuleDist = sdCapsule(p, vec3(4, 0.6, 6), vec3(5, 2, 6), .2);
    float d = min(sphereDist, planeDist);
    d = min(d, capsuleDist);
    return d;
}


float RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.0;

    for(int i=0; i < MAX_STEPS; i++) { 
        vec3 p = ro + rd * dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO > MAX_DIST || dS < SURF_DIST) {
            break;
        }
    }

    return dO;
}


vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.01, 0);

    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );

    return normalize(n);
}


float GetLight(vec3 p, vec3 nor) {
    vec3 lightPos = vec3(0, 4, 6);
    lightPos.xz += vec2(sin(iGlobalTime), cos(iGlobalTime)) * 4.;
    vec3 l = normalize(lightPos - p);
    float dif = clamp(dot(nor, l), 0., 1.);
    float d = RayMarch(p + nor*SURF_DIST*2., l);
    if(d < length(lightPos - p)) {
        dif *= .2;
    }
    return dif;
}


vec3 GetColor(vec3 p) {
    vec3 nor = GetNormal(p);
    vec3 sun_dir = normalize(vec3(0.8, 0.4, 0.2));
    float sun_dif = GetLight(p, nor);
    float sky_dif = clamp( dot(nor, vec3(0, 1, 0)), 0.0, 1.0);
    vec3 col = vec3(1.0, 0.7, 0.5)*sun_dif;
    col += vec3(0.0,0.2,0.4)*sky_dif;
    return col;
}


void main() {
    /* Shadertoy parameters */
    float time = iGlobalTime;
    vec2 U = gl_FragCoord.xy;

    vec2 uv = (2.*U-R)/R.y;
    vec3 col = vec3(0);

    vec3 ro = vec3(0, 5, -3);
    vec3 rd = normalize(vec3(uv.x, uv.y-.4, 1));

    float d = RayMarch(ro, rd);

    if(d < MAX_DIST) {
        vec3 p = ro + rd * d;
        col = GetColor(p);

        if(p.y < 0.001) {
            col = vec3(0,0,0);
        }
    }

    vec4 O = vec4(col, 1.0);
    gl_FragColor = O;
}
