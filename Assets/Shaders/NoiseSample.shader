Shader "Sasami/NoiseSample"
{
    Properties
    {
        _NoiseTilingOffset ("NoiseTex Tiling(x,y)/Offset(z,w)", Vector) = (0.1,0.1,0,0)
        _NoiseSizeScroll   ("NoiseTex Size(x,y)/Scroll(z,w)"  , Vector) = (16,16,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            fixed4 _NoiseTilingOffset;
            fixed4 _NoiseSizeScroll;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_NOISE_TEX(v.uv, _NoiseTilingOffset, _NoiseSizeScroll);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed p = perlinNoise(i.uv, _NoiseSizeScroll.xy);
                //return fixed4 ( p, p, p, 1 );   // 白黒のノイズ画像を生成
                return fixed4 ( normalNoise(i.uv, _NoiseSizeScroll.xy), 1 );  // 法線マップ用パーリンノイズ画像を生成
            }
            ENDCG
        }
    }
}


