Shader "Sasami/NoiseDistGrabTexture"
{
    Properties
    {
        _NoiseTilingOffset ("NoiseTex Tiling(x,y)/Offset(z,w)", Vector) = (0.1,0.1,0,0)
        _NoiseSizeScroll   ("NoiseTex Size(x,y)/Scroll(z,w)"  , Vector) = (16,16,0,0)
        _DistortionPower   ("Distortion Power", Float ) = 0

        _NormalScale       ("Normal Scale", Float ) = 0
        _SpecularPower     ("Specular Power", Range(0.0, 1.0) ) = 0
        _Shininess         ("Shininess", Range(0.001, 1.0) ) = 0
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass {
            "_BackgroundTexture"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "SasamiNoise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 uvgrab : TEXCOORD0;
                fixed2 uvdist : TEXCOORD1;

                fixed3 tangentToWorld[3] : TEXCOORD2;
                fixed3 viewWorld : TEXCOORD5;
                fixed3 lightWorld : TEXCOORD6;
            };

            sampler2D _BackgroundTexture;

            fixed4 _NoiseTilingOffset;
            fixed4 _NoiseSizeScroll;
            fixed _DistortionPower;

            fixed _SpecularPower;
            fixed _Shininess;
            fixed _NormalScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uvgrab = ComputeGrabScreenPos(o.vertex);
                o.uvdist = TRANSFORM_NOISE_TEX(v.uv, _NoiseTilingOffset, _NoiseSizeScroll);

                // tangent to world
                fixed3 normalWorld   = UnityObjectToWorldNormal(v.normal);
                fixed4 tangentWorld  = fixed4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                fixed3 binormalWorld = cross(normalWorld, tangentWorld.xyz) * (tangentWorld.w * unity_WorldTransformParams.w);
                o.tangentToWorld[0].xyz = tangentWorld;
                o.tangentToWorld[1].xyz = binormalWorld;
                o.tangentToWorld[2].xyz = normalWorld;

                // world-space view and light vector
                fixed3 posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.viewWorld  = normalize(UnityWorldSpaceViewDir(posWorld));
                o.lightWorld = normalize(UnityWorldSpaceLightDir(posWorld));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 dist = normalNoise(i.uvdist, _NoiseSizeScroll.xy);   // perlinノイズで算出した法線を得る
                dist = dist * 2 - 1;                                        // 範囲を0.0～1.0から-1.0～1.0へ変換

                i.uvgrab.xy += dist.xy * _DistortionPower;                  // 歪み量だけ、メインテクスチャのUVをずらす

                fixed4 color = tex2Dproj( _BackgroundTexture,UNITY_PROJ_COORD(i.uvgrab) );

                // world-space normal
                fixed3 normalXY = i.tangentToWorld[0].xyz * dist.x + i.tangentToWorld[1].xyz * dist.y, normalZ = i.tangentToWorld[2].xyz * dist.z;
                fixed3 normalWorld = normalize(normalXY * _NormalScale + normalZ);

                // phong specular
                half NdotL = max(0, dot (normalWorld, i.lightWorld));
                float3 R = normalize( -i.lightWorld + 2.0 * normalWorld * NdotL );
                float3 spec = pow(max(0, dot(R, i.viewWorld)), _Shininess * 10) * _SpecularPower * 10;
                color.rgb += spec;

                return color;
            }
            ENDCG
        }
    }
}