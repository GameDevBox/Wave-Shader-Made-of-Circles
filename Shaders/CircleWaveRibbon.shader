// GameDevBox - Circle Wave Ribbon (URP)
// Use it on a quad that's taller than it is wide. uv.y = 0 is the bottom of the ribbon, 1 is the tip.
Shader "GameDevBox/Circle Wave Ribbon"
{
    Properties
    {
        [Header(Wave)]
        _Frequency ("Frequency", Range(0.5, 12)) = 5
        _Speed ("Speed", Range(-4, 4)) = 0.5
        _Phase ("Phase", Float) = 0
        _TimeOffset ("Time Offset", Float) = 0
        _Amplitude ("Amplitude", Range(0, 0.6)) = 0.24
        _AmplitudeCurve ("Amplitude Curve", Range(0.2, 4)) = 0.6
        _Roundness ("Roundness", Range(0.5, 2)) = 0.5
        _SineBlend ("Sine Blend", Range(0, 1)) = 0
        _Detail ("Detail Wave", Range(0, 1)) = 0.06
        _DetailFrequency ("Detail Frequency", Range(1, 6)) = 2.3

        [Header(Noise)]
        _DriftStrength ("Drift", Range(0, 0.3)) = 0.025
        _DriftScale ("Drift Scale", Range(0.5, 10)) = 2.5
        _DriftSpeed ("Drift Speed", Range(0, 4)) = 0.6
        _EdgeWobble ("Edge Wobble", Range(0, 0.05)) = 0.003
        _WobbleScale ("Wobble Scale", Range(1, 30)) = 8

        [Header(Shape)]
        _Aspect ("Quad Height / Width", Float) = 2
        _BaseWidth ("Base Width", Range(0.01, 0.5)) = 0.22
        _TipWidth ("Tip Width", Range(0, 0.2)) = 0.01
        _Taper ("Taper", Range(0.2, 4)) = 0.9
        _BaseRound ("Base Roundness", Range(0, 0.3)) = 0.12
        _BaseLift ("Base Lift", Range(0, 0.3)) = 0.06
        _EvenThickness ("Even Thickness", Range(0, 1)) = 0.25
        _BulgeStrength ("Bulge", Range(0, 1)) = 0.15
        _BulgeFrequency ("Bulge Frequency", Range(0, 12)) = 2.2
        _BulgeSpeed ("Bulge Speed", Range(-6, 6)) = 0.9

        [Header(Color)]
        _FillColor ("Fill", Color) = (1, 0.97, 1, 1)
        _EdgeColor ("Edge", Color) = (0.86, 0.74, 0.96, 1)
        _EdgeSize ("Edge Size", Range(0, 0.15)) = 0.035
        _Brightness ("Brightness", Range(0, 4)) = 1
        _Shading ("Shading", Range(0, 1)) = 0.06
        _ShadingScale ("Shading Scale", Range(1, 30)) = 7
        _ShadingSpeed ("Shading Speed", Range(-6, 6)) = 1

        [Header(Glow)]
        [HDR] _GlowColor ("Glow", Color) = (0.55, 0.3, 1.1, 1)
        _GlowSize ("Glow Size", Range(0.001, 0.3)) = 0.04
        _GlowStrength ("Glow Strength", Range(0, 3)) = 0.12

        [Header(Tip)]
        _TipFade ("Tip Fade", Range(0.001, 0.5)) = 0.06
        _TipBreakup ("Tip Breakup", Range(0, 1)) = 0.12
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        Blend One OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "Unlit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "CircleWaveRibbon.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _Frequency, _Speed, _Phase, _TimeOffset, _Amplitude, _AmplitudeCurve, _Roundness, _SineBlend, _Detail, _DetailFrequency;
                float _DriftStrength, _DriftScale, _DriftSpeed, _EdgeWobble, _WobbleScale;
                float _Aspect, _BaseWidth, _TipWidth, _Taper, _BaseRound, _BaseLift, _EvenThickness;
                float _BulgeStrength, _BulgeFrequency, _BulgeSpeed;
                float4 _FillColor, _EdgeColor;
                float _EdgeSize, _Brightness, _Shading, _ShadingScale, _ShadingSpeed;
                float4 _GlowColor;
                float _GlowSize, _GlowStrength;
                float _TipFade, _TipBreakup;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs pos = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = pos.positionCS;
                output.uv = input.uv;
                output.fogCoord = ComputeFogFactor(pos.positionCS.z);
                return output;
            }

            float Center(float y, float t)
            {
                return WaveOffset(y, t, _Frequency, _Speed, _Phase, _Roundness, _SineBlend, _Detail, _DetailFrequency,
                                  _Amplitude, _AmplitudeCurve);
            }

            // Thick round blob at the bottom, thin at the top.
            float Width(float y, float t)
            {
                float h = saturate(y - _BaseLift);
                float w = _BaseWidth * pow(1.0 - h, _Taper) + _TipWidth;
                w *= 1.0 + _BulgeStrength * (1.0 - h) * sin((y * _BulgeFrequency - t * _BulgeSpeed) * TWO_PI);

                // close the bottom off with a quarter circle so it doesn't get cut flat
                float c = saturate((_BaseRound + _BaseLift - y) / max(_BaseRound, 1e-4));
                return w * sqrt(saturate(1.0 - c * c));
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float t = _Time.y + _TimeOffset;
                float y = input.uv.y;
                float aspect = max(_Aspect, 0.01);
                // x and y in the same units (one quad width), so circles stay circles
                float2 p = float2(input.uv.x - 0.5, y * aspect);
                float drift = Drift(y, t, _AmplitudeCurve, _DriftStrength, _DriftScale, _DriftSpeed);

                // Classic way: just measure sideways from the centre line.
                // This is what makes the blobs at every turn.
                float sideways = abs(p.x - Center(y, t) - drift) - Width(y, t);

                // Even thickness: real distance to the curve. Walk up and down a bit,
                // join the points into short lines and keep the closest one.
                // Anything further away vertically than the widest part can't be the closest point.
                float range = (_BaseWidth * (1.0 + _BulgeStrength) + _GlowSize * 3.0) / aspect;
                const int STEPS = 16;
                float stepY = range / STEPS;
                // put the points on a fixed grid, so every pixel measures against the same curve
                // (points that follow the pixel's own y leave thin horizontal streaks)
                float yBase = floor(y / stepY) * stepY;
                float even = 1e5;
                float yA = yBase - range;
                float2 a = float2(Center(yA, t) + drift, yA * aspect);
                float wA = Width(yA, t);
                [unroll]
                for (int i = 1 - STEPS; i <= STEPS + 1; i++)
                {
                    float yB = yBase + stepY * i;
                    float2 b = float2(Center(yB, t) + drift, yB * aspect);
                    float wB = Width(yB, t);

                    float2 pa = p - a;
                    float2 ba = b - a;
                    float k = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-8));
                    even = min(even, length(pa - ba * k) - lerp(wA, wB, k));

                    a = b;
                    wA = wB;
                }

                float d = lerp(sideways, even, _EvenThickness);
                d = max(d, (_BaseLift - y) * aspect); // nothing below the base
                d += (Fbm(p * _WobbleScale - float2(0, t * 0.7)) * 2.0 - 1.0) * _EdgeWobble;

                float aa = clamp(fwidth(d), 1e-4, 0.01);
                float mask = 1.0 - smoothstep(-aa, aa, d);

                // fade the very tip and let it break apart a little
                float tipFade = 1.0 - smoothstep(1.0 - _TipFade, 1.0, y);
                float breakup = smoothstep(1.0 - _TipBreakup, 1.0, y);
                float n = Fbm(float2(p.x * 9.0 + 3.1, y * 8.0 - t * 1.2)) * 1.15;
                mask *= tipFade * (_TipBreakup > 0.0 ? smoothstep(breakup - 0.1, breakup + 0.1, n) : 1.0);

                float3 color = lerp(_FillColor.rgb, _EdgeColor.rgb, smoothstep(-_EdgeSize, 0.0, d));
                float shade = Fbm(float2(p.x * 3.0 + 11.7, y * _ShadingScale - t * _ShadingSpeed));
                color *= (1.0 + (shade - 0.5) * 2.0 * _Shading) * _Brightness;

                // keep the glow off the quad's sides
                float sides = smoothstep(0.5, 0.38, abs(p.x));
                // glow by the real distance too: the sideways one jumps where the wave turns fast,
                // which leaves hard horizontal edges in the glow
                float glowDist = max(min(d, even), 0.0);
                float glow = exp(-glowDist / _GlowSize) * _GlowStrength * tipFade * (1.0 - mask) * sides;

                float3 rgb = max(color * mask + _GlowColor.rgb * glow, 0.0);
                float alpha = saturate(mask + glow * 0.3);
                return half4(MixFog(rgb, input.fogCoord), alpha);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
