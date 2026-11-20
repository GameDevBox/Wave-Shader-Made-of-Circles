# Circle Wave Ribbon (URP)

A solid, crisp shape (a round blob at the base that tapers to a thin, curling wisp) whose centre line follows a **circle wave**: a wave built from half circles instead of a sine.

```hlsl
float a          = frac(x) * 2 - 1;              // -1..1 in every segment
float circle     = pow(1 - a * a, roundness);    // roundness 0.5 = exact half circle
float sign       = step(0.5, frac(x / 2)) * 2 - 1; // flip every other segment
float circleWave = circle * sign;
```

From the GameDevBox video on how this shader works. The video walks through the HLSL version line by line, and the Shader Graph version is here as an extra.

## Install

Tested in Unity 6000.6 with URP 17.6.

1. Copy this **Circle Wave Ribbon** folder anywhere under `Assets/`.
2. Open `Scenes/Circle Wave Ribbon Demo.unity`, or put one of the materials on a Quad (see **Use it** below).

The **GameDevBox → Circle Wave Ribbon** menu rebuilds the demo scene. It expects the folder at `Assets/GameDevBox/Tutorials/Circle Wave Ribbon`. The shaders and materials work from any location.

## What's here

| Path | What it is |
| --- | --- |
| `Shaders/CircleWaveRibbon.shader` | The full version: **GameDevBox/Circle Wave Ribbon** (URP, unlit, transparent, premultiplied) |
| `Shaders/CircleWaveRibbon.hlsl` | Shared math: the circle wave, the noise, and the centre-line helpers |
| `Shaders/RadialBackdrop.shader` | **GameDevBox/Radial Backdrop**: the dark background with a purple glow, for presenting it |
| `Shader Graph/Circle Wave Ribbon.shadergraph` | The same idea in nodes: **GameDevBox/Shader Graph/Circle Wave Ribbon** (URP Unlit, transparent, alpha blend). This is the classic method: offset the UVs, then cut out the shape |
| `Materials/` | Spirit (white on purple, like the reference), Ember (warm), Toxic (green, rounder and half sine), Shader Graph Ribbon, Backdrop |
| `Scenes/Circle Wave Ribbon Demo.unity` | The three HLSL ribbons on the glowing backdrop with light Bloom, no tonemapping (so the fill stays white). The Shader Graph ribbon is in the scene but disabled |
| `Editor/CircleWaveRibbonSetup.cs` | Menu **GameDevBox → Circle Wave Ribbon**: rebuild the demo scene, capture test frames |

## Use it

1. Add a **Quad**, make it taller than wide (e.g. scale 1.8 × 3.6), and give it one of the materials.
2. Set **Quad Height / Width** on the material to match (3.6 / 1.8 = 2), so the ribbon keeps an even thickness.
3. Add a Volume with **Bloom**: the colours are HDR, so the core and glow bloom naturally.

## What the HLSL version adds

- **Even Thickness slider.** At 0 you get the classic look: the shape is measured sideways from the centre line, so it bulges at every turn. At 1 it measures the real distance to the curve and keeps the same thickness everywhere. The default of 0.25 is mostly classic.
- **Shape controls:** base width, tip width, taper, base roundness and lift, travelling bulges.
- **Roundness and Sine Blend:** sharp half circles (0.5), softer corners (1+), or a blend towards a sine.
- **Noise:** slow sideways drift, a small detail wave, and a little edge wobble.
- **Look:** flat fill, a soft edge colour, faint moving shading, a light glow, and a tip that fades and breaks up.
- **Time Offset,** to run several copies out of sync.

The Shader Graph is the classic version in nodes, with the same shape profile. It's meant to be built step by step on camera.

`Capture Motion Frames` in the menu renders 4 seconds of the close-up as numbered PNGs in `Recordings/`.
