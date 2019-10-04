#define R iResolution.xy


mat3 rotateY(float angle) {
	float c = cos(angle), s = sin(angle);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}


void main() {
    /* Shadertoy parameters */
    float time = iGlobalTime;
    vec2 U = gl_FragCoord.xy;

    vec2 uv = (2.*U-R)/R.y;
    vec3 col = vec3(0);

    vec3 ro = vec3(0, 8, -10);
    vec3 rd = normalize(vec3(uv, 0) - ro);
    mat3 rot = rotateY(time / 4.);
    ro *= rot; 
    rd *= rot;

    float t = 0.;
    int i = 0;
    float dS = 1e10;
    vec3 p = vec3(0);
    int maxSteps = 100;
    float eps = 0.001;

    for(i=0; i < maxSteps; i++) {
        p = ro + t * rd;
        dS = length(vec2(length(p.xz) - 0.5, p.y)) - 0.225; // Torus SDF
        if(dS < eps) {
            break;
        }
        t += dS;
    }

    if(dS < eps) {
        // Spherical coordinates: r, theta and phi
        float r = length(p);
        float theta = atan(p.y, p.x);
        float phi = atan(p.z, sqrt(p.x * p.x + p.y * p.y));
        col += vec3(sin(theta) * .5 + .5, sin(phi) * .5 + .5, r);
    }
    else {
        // Background
        col += mix(vec3(0.4), vec3(0.7), uv.y + 0.5);
    }

    vec4 O = vec4(col, 1.0);
    gl_FragColor = O;
}
