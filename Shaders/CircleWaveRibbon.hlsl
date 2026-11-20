#ifndef CIRCLE_WAVE_RIBBON_INCLUDED
#define CIRCLE_WAVE_RIBBON_INCLUDED

float Hash21(float2 p)
{
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

float ValueNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = Hash21(i);
    float b = Hash21(i + float2(1, 0));
    float c = Hash21(i + float2(0, 1));
    float d = Hash21(i + float2(1, 1));
    return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
}

float Fbm(float2 p)
{
    float value = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++)
    {
        value += ValueNoise(p) * amp;
        p = p * 2.03 + 17.1;
        amp *= 0.5;
    }
    return value;
}

// Half circles instead of a sine.
// roundness 0.5 = sqrt, so a true half circle. Bigger values soften the corner
// where two circles meet.
float CircleWave(float x, float roundness)
{
    float a = frac(x) * 2.0 - 1.0;
    float circle = pow(max(1.0 - a * a, 1e-5), roundness);
    float sign = step(0.5, frac(x * 0.5)) * 2.0 - 1.0;
    return circle * sign;
}

float Wave(float x, float roundness, float sineBlend)
{
    // -sin so it bends the same way as the circle wave
    return lerp(CircleWave(x, roundness), -sin(x * PI), sineBlend);
}

// How far the middle of the ribbon moves sideways at height y.
float WaveOffset(float y, float time, float frequency, float speed, float phase, float roundness, float sineBlend,
                 float detail, float detailFrequency, float amplitude, float amplitudeCurve)
{
    float x = y * frequency + phase - time * speed;
    float wave = Wave(x, roundness, sineBlend);
    wave += Wave(x * detailFrequency + 0.37, roundness, 1.0) * detail;

    // pinned at the bottom, free at the top
    return wave * amplitude * pow(saturate(y), amplitudeCurve);
}

float Drift(float y, float time, float amplitudeCurve, float strength, float scale, float speed)
{
    float n = Fbm(float2(y * scale, time * speed)) * 2.0 - 1.0;
    return n * strength * pow(saturate(y), amplitudeCurve);
}

#endif
