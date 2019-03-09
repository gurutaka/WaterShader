Shader "PartialDelivativeBlending"
{
    Properties {
        _MainTex ("Base (RGB)", 2D)                  = "white" {}
        [Normal]
        _NormalMap1 ("Normal Map 1", 2D)         = "bump" {}
        [Normal]
        _NormalMap2 ("Normal Map 2", 2D)         = "bump" {}
        _Shininess ("Shininess", Range(0.0, 1.0))  = 0.078125
        _BlendRate ("Blend Rate", Range(0.0, 1.0)) = 0.5
    }
    SubShader {

        Tags { "Queue"="Geometry" "RenderType"="Opaque"}

        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
           #include "UnityCG.cginc"

           #pragma vertex vert
           #pragma fragment frag

            half4 _LightColor0;
            sampler2D _MainTex;
            sampler2D _NormalMap1;
            sampler2D _NormalMap2;
            half _Shininess;
            half _BlendRate;

            struct appdata {
                float4 vertex       : POSITION;
                half2 texcoord      : TEXCOORD0;
                half3 normal        : NORMAL;
                half4 tangent       : TANGENT;
            };

            struct v2f {
                float4 pos          : SV_POSITION;
                half2 uv            : TEXCOORD0;
                half3 lightDir      : TEXCOORD1;
                half3 viewDir       : TEXCOORD2;
            };

            v2f vert(appdata v) {
                v2f o;

                o.pos       = UnityObjectToClipPos(v.vertex);
                o.uv        = v.texcoord.xy;
                TANGENT_SPACE_ROTATION;
                o.lightDir  = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir   = mul(rotation, ObjSpaceViewDir(v.vertex));

                return o;
            }

            fixed4 frag(v2f i) : COLOR {
                i.lightDir          = normalize(i.lightDir);
                i.viewDir           = normalize(i.viewDir);
                half3 halfDir       = normalize(i.lightDir + i.viewDir);

                fixed4 tex          = tex2D(_MainTex, i.uv);
                half3 normal1       = UnpackNormal(tex2D(_NormalMap1, i.uv));
                half3 normal2       = UnpackNormal(tex2D(_NormalMap2, i.uv));
                // 正規化が保証されていなかったらしておく（処理負荷的にはしたくない）
                normal1     = normalize(normal1);
                normal2     = normalize(normal2);
                // ブレンドする
                float2 pd           = lerp(normal1.xy / normal1.z, normal2.xy / normal2.z, _BlendRate);
                float3 normal       = normalize(float3(pd, 1));

                // 適当にライティング計算
                half3 diffuse       = max(0, dot(normal, i.lightDir)) * _LightColor0.rgb;
                half3 specular      = pow(max(0, dot(normal, halfDir)), _Shininess * 128.0) * _LightColor0.rgb;

                fixed4 color;
                color.rgb           = tex.rgb * diffuse + specular;
                return color;
            }

            ENDCG
        }
    }
}