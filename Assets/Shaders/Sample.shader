Shader "Unlit/BlinnPhong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex ("NormalMap", 2D) = "white" {}
        _Shininess ("Shininess", Range(0 ,1)) = 0.7
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 halfDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            float4 _LightColor0;;
            float _Shininess;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                o.halfDir = normalize(o.lightDir + o.viewDir);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                i.lightDir = normalize(i.lightDir);
                i.viewDir = normalize(i.viewDir);
                float3 normal = UnpackNormal(tex2D(_NormalTex, i.uv));

                float4 diff = saturate(dot(normal, i.lightDir)) * _LightColor0;
                float3 spec = pow(max(0, dot(normal, i.halfDir)), _Shininess * 128) * _LightColor0;

                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb = col.rgb * diff + spec;
                return col;
            }
            ENDCG
        }
    }
}