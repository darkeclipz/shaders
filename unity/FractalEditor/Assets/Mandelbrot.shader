Shader "Explorer/Mandelbrot"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Area ("Area", vector) = (0, 0, 4, 4)
        _Angle("Angle", range(-3.1415, 3.1415)) = 0
        _MaxIterations("MaxIterations", float) = 255
        _Color("Color", range(0, 1)) = 0.5
        _Repeat("Repeat", float) = 1
        _Speed("Speed", float) = 1
        _Symmetry("Symmetry", range(0, 1)) = 0
        _Supersampling("Supersampling", range(1, 4)) = 1
        _Julia("Julia", range(0, 1)) = 0
        _JuliaOffset("JuliaOffset", vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            
            float _MaxIterations;
            float _Angle;
            float4 _Area;
            float _Color;
            sampler2D _MainTex;
            float _Repeat;
            float _Speed;
            float _Symmetry;
            float _Supersampling;
            float _Julia;
            float4 _JuliaOffset;

            float2 rot(float2 p, float2 pivot, float a)
            {
                float s = sin(a);
                float c = cos(a);

                p -= pivot;
                p = float2(p.x*c - p.y*s, p.x*s + p.y*c);
                p += pivot;

                return p;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 res = 0;

                float2 uv = i.uv - 0.5;
                uv = abs(uv);
                uv = rot(uv, 0., 0.25*3.14);
                uv = abs(uv);

                uv = lerp(i.uv - 0.5, uv, _Symmetry);

                float2 c = _Area.xy + uv*_Area.zw;
                c = rot(c, _Area.xy, _Angle);

                float2 z, zPrev;

                z = lerp(0, rot(_Area.xy + uv*_Area.zw, _Area.xy, _Angle), _Julia);
                c = lerp(c, _JuliaOffset.xy, _Julia);
              
                float iter;
                float r = 10;
                float r2 = r*r;
           
                for(iter = 0; iter < _MaxIterations; iter++) 
                {
                    zPrev = rot(z, 0.0, +_Time.y);
                    z = float2(z.x*z.x-z.y*z.y, 2*z.x*z.y) + c;

                    if(dot(z,zPrev) > r2) 
                    {
                        break;
                    }
                }

                if(iter >= _MaxIterations) return 0;

                float dist = length(z);
                float fracIter = log2(log(dist) / log(r)); // double exponential interpolation
                iter -= fracIter;
                float m = sqrt(iter / _MaxIterations);
                float4 col = tex2D(_MainTex, float2(m * _Repeat + _Time.y * _Speed, _Color));
                float angle = atan2(z.x, z.y); // [-pi, pi]
                col *= smoothstep(3, 0, fracIter);
                col *= sin(angle * 2 + _Time.y*4.) * 0.2 + 1;

                res += col;
            
                res /= (_Supersampling * _Supersampling);

                return res;
            }
            ENDCG
        }
    }
}
