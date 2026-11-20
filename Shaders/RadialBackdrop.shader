// A dark backdrop with a soft coloured glow, for presenting the ribbon (GameDevBox).
Shader "GameDevBox/Radial Backdrop"
{
    Properties
    {
        _OuterColor ("Outer", Color) = (0.02, 0.02, 0.06, 1)
        _InnerColor ("Glow", Color) = (0.22, 0.06, 0.38, 1)
        _Center ("Glow Centre (UV)", Vector) = (0.5, 0.18, 0, 0)
        _Radius ("Glow Radius", Range(0.05, 2)) = 0.55
        _Falloff ("Falloff", Range(0.2, 6)) = 1.6
        _Aspect ("Quad Width / Height", Float) = 1.78
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry-100" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            Name "Unlit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _OuterColor, _InnerColor, _Center;
                float _Radius, _Falloff, _Aspect;
            CBUFFER_END
            struct A { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct V { float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0; };
            V vert(A i) { V o; o.positionCS = TransformObjectToHClip(i.positionOS.xyz); o.uv = i.uv; return o; }
            half4 frag(V i) : SV_Target
            {
                float2 d = (i.uv - _Center.xy) * float2(_Aspect, 1.0);
                float g = pow(saturate(1.0 - length(d) / _Radius), _Falloff);
                return half4(lerp(_OuterColor.rgb, _InnerColor.rgb, g), 1);
            }
            ENDHLSL
        }
    }
}
