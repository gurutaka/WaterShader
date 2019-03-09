// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FresnelReflection"
{
    Properties
    {
        _NormalTex1 ("NormalTex1", 2D) = "white" {}
        _NormalTex2 ("NormalTex2", 2D) = "white" {}
        [PowerSlider(0.1)] _F0 ("F0", Range(0.0, 0.5)) = 0.02
        _SurfaceColor ("SurfaceColor" , Color) = (1, 1, 1, 1)
        _DeepColor ("DeepColor" , Color) = (1, 1, 1, 1)
        _Deepness ("Deepness", Range(3, 10))  = 5
        _BlendRate ("Blend Rate", Range(0.0, 1.0)) = 0.5
        _Shininess ("Shininess", Range(0 ,5)) = 0.7
        _SpecularPower ("SpecularPower", Range(0 ,3)) = 1
        _FlowSpeedNormal1 ("FlowSpeedNormal1", Range(0 ,5)) = 1
        _FlowSpeedNormal2 ("FlowSpeedNormal2", Range(0 ,5)) = 1
    }
    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque"}
        //LOD 200

        Pass
        {
           Tags {"LightMode"="ForwardBase"}
           CGPROGRAM
            
           #pragma vertex vert
           #pragma fragment frag
            
           #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                // 頂点の法線と接線の情報を取得できるようにする
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 position  : SV_POSITION;
                half vdotn : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 halfDir : TEXCOORD3;
                float2 uv  : TEXCOORD4;
            };
            
            sampler2D _NormalTex1;
            sampler2D _NormalTex2;
            float4 _NormalTex_ST;
            float4 _LightColor0;
            float _F0;
            float _Deepness;
            fixed3 _SurfaceColor;
            fixed3 _DeepColor;
            float _Shininess;
            float _SpecularPower;
            half _BlendRate;
            half _FlowSpeedNormal1;
            half _FlowSpeedNormal2;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                half3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.vdotn = dot(viewDir, v.normal.xyz);
                
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                o.halfDir = normalize(o.lightDir + o.viewDir);
                o.uv = v.texcoord.xy;
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                i.lightDir = normalize(i.lightDir);
                i.viewDir = normalize(i.viewDir);
                
                //UVスクロール
                half t = _Time.x;
                half2 uv = i.uv;
                uv.y += t * _FlowSpeedNormal1;
                //uv.x += t * _FlowSpeedNormal1;
                
                float3 normal1 = UnpackNormal(tex2D(_NormalTex1, uv));
                
                i.uv.y += t * _FlowSpeedNormal2;
                //i.uv.x += t * _FlowSpeedNormal2;
                float3 normal2 = UnpackNormal(tex2D(_NormalTex2, i.uv));
                
                
                // 正規化が保証されていなかったらしておく（処理負荷的にはしたくない）
                normal1     = normalize(normal1);
                normal2     = normalize(normal2);
                
                // ブレンドする
                float2 pd           = lerp(normal1.xy / normal1.z, normal2.xy / normal2.z, _BlendRate);
                float3 normal       = normalize(float3(pd, 1));
                
                //ライティング
                float4 diff = saturate(dot(normal, i.lightDir)) * _LightColor0 * _SpecularPower;
                float3 spec = pow(max(0, dot(normal, i.halfDir)), _Shininess * 128) * _LightColor0;
                
                half fresnel = _F0 + (1.0h - _F0) * pow(1.0h - i.vdotn, _Deepness);//フレネル効果
                
                
                fixed4 col;
                col.rgb = lerp(_DeepColor, _SurfaceColor, fresnel);
                col.rgb = col.rgb * diff  + spec;
                return col;
            }
            ENDCG
        }
    }
}