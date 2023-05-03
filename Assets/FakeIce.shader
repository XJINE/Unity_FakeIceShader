Shader "Custom/FakeIce"
{
    Properties
    {
        _Color        ("Color",         Color      ) = (1,1,1,1)
        _MainTex      ("Albedo (RGB)",  2D         ) = "white" {}
        _Glossiness   ("Smoothness",    Range(0, 1)) = 0.5
        _Metallic     ("Metallic",      Range(0, 1)) = 0.0
        _ComplexScale ("Complex Scale", Float      ) = 1
        _ComplexPower ("Complex Power", Float      ) = 1
        _Opacity      ("Opacity",       Range(0, 1)) = 0.2
     }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha

        Tags
        {
            "Queue" = "Transparent+1"
        }
        GrabPass
        {
            "_GrabTex"
        }

        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows alpha:blend vertex:vert
        #pragma target 3.0

        struct Input
        {
            float2 mainUV      : TEXCOORD0;
            float4 grabUV      : TEXCOORD1;
            float3 viewDir     : TEXCOORD2;
            float3 worldNormal : TEXCOORD3;
        };

        sampler2D _MainTex;
        sampler2D _GrabTex;

        float4 _Color;
        float  _Glossiness;
        float  _Metallic;
        float  _ComplexScale;
        float  _ComplexPower;
        float  _Opacity;

        float random(float2 seeds)
        {
            return frac(sin(dot(seeds, float2(12.9898, 78.233))) * 43758.5453);
        }

        float perlinNoise(float2 seeds) 
        {
            float2 p = floor(seeds);
            float2 f = frac (seeds);
            float2 u = f * f * (3.0 - 2.0 * f);

            float v00 = random(p + float2(0,0));
            float v10 = random(p + float2(1,0));
            float v01 = random(p + float2(0,1));
            float v11 = random(p + float2(1,1));

            return lerp(lerp(dot(v00, f - float2(0,0)), dot(v10, f - float2(1,0)), u.x),
                        lerp(dot(v01, f - float2(0,1)), dot(v11, f - float2(1,1)), u.x), 
                        u.y) + 0.5;
        }

        void vert(inout appdata_full v, out Input o)
        {
            o.mainUV      = v.texcoord;
            o.grabUV      = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex));
            o.worldNormal = normalize(mul(v.normal, unity_WorldToObject));
            o.viewDir     = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.vertex));
        }

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            i.grabUV.xy += _ComplexPower * perlinNoise(i.mainUV * _ComplexScale);

            float4 colorGrab = tex2Dproj(_GrabTex, i.grabUV) * _Color;

            o.Albedo     = colorGrab;
            o.Metallic   = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha      = 1 + _Opacity - dot(i.viewDir, i.worldNormal);
        }

        ENDCG
    }

    FallBack "Diffuse"
}