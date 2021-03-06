﻿Shader "FlowingNormalMap"
{
    Properties
    {
        _MainTex ("Main Tex", 2D)                                = "white" {}
        _FlowMap ("Flow Map", 2D)                                    = "white" {}
        _FlowSpeed ("Flow Speed", float)                            = 1.0
        _FlowIntensity ("Flow Intensity", float)                    = 1.0
        _Shininess ("Shininess", Range(0, 1))  = 0.75
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            Blend One Zero
            Lighting Off

            CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
            
           #include "UnityCG.cginc"
           #include "UnityLightingCommon.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _FlowMap;
            float _FlowIntensity;
            float _FlowSpeed;
            half _Shininess;

            struct appdata
            {
                float4 vertex       : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 diff : COLOR0;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex        = UnityObjectToClipPos(v.vertex);
                o.uv            = TRANSFORM_TEX(v.uv, _MainTex);
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                o.diff = nl * _LightColor0;
                o.diff.rgb += ShadeSH9(half4(worldNormal,1));
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 流れの方向を取得
                float2 flowDir = tex2D(_FlowMap  , i.uv) - 0.5;
                flowDir  *= _FlowIntensity;
                
                float progress1 = frac(_Time.x * _FlowSpeed);
                float progress2 = frac(_Time.x * _FlowSpeed + 0.5);
                float2 uv1 = i.uv + flowDir * progress1;
                float2 uv2 = i.uv + flowDir * progress2;
                float lerpRate = abs((0.5 - progress1) / 0.5);
                float4 col1 = tex2D(_MainTex, uv1);
                float4 col2 = tex2D(_MainTex, uv2);
                fixed4 color = lerp(col1, col2, lerpRate) * i.diff * _Shininess;
                return color;
                
            }
            ENDCG
        }
    }
}