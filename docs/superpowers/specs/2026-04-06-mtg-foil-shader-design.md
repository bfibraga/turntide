# MTG Card Foil Shader System - Design Spec

**Date:** 2026-04-06  
**Status:** Approved

## Overview

Implement three foil treatments (regular, non-foil, etched) for MTG cards using a layered SubViewport shader stack with `.gdshaderinc` includes for reusable foil logic.

## Goals

- Non-foil: No visual effect (baseline)
- Regular foil: Rainbow holographic shimmer with edge emphasis
- Etched foil: Metallic specular effect with softer edge response
- Static effect with subtle shimmer based on card angle and time

## Architecture

### Layer Structure
```
CardView (Control)
└── SubViewportContainer (with 3D perspective shader)
    └── SubViewport
        └── TextureRect (card image + rounded corners shader)
            └── FxSubViewport (separate SubViewport)
                └── FoilOverlay (ColorRect with foil shader)
```

### File Structure
```
client/
├── shaders/cards/foil/
│   ├── foil_common.gdshaderinc      # Noise functions, UV helpers
│   ├── foil_regular.gdshaderinc      # Rainbow holographic effect  
│   ├── foil_etched.gdshaderinc       # Metallic specular effect
│   └── foil_base.gdshader            # Main shader with type switching
│
├── scenes/card/foil/
│   └── foil_layer.tscn               # FxSubViewport + ColorRect scene
│
└── scripts/card/
    ├── foil_overlay.gd               # Script for FoilOverlay node
    └── view.gd                       # Modify to apply foil
```

## Shader Details

### foil_common.gdshaderinc
Shared utilities for all foil types:
- `hash(vec2)` - pseudo-random hash function
- `smoothNoise(vec2)` - smooth Perlin-like noise
- `fbm(vec2, int)` - fractal brownian motion (4 octaves)
- `fresnel(float)` - edge emphasis calculation
- `distortUV(vec2, float)` - subtle UV warping for shimmer

### foil_regular.gdshaderinc
Rainbow holographic effect:
- Hue-based rainbow spectrum mapping
- Fresnel-weighted edge emphasis (stronger at card borders)
- Time-based animated shimmer
- Holographic interference pattern via noise

### foil_etched.gdshaderinc
Metallic specular effect:
- Metallic specular highlight calculation
- Softer edge response (no rainbow)
- Coarser noise scale for larger patterns
- Subtle animated gleam with different timing

### foil_base.gdshader
Main shader with foil type switching:
```gdshader
shader_type canvas_item;
#include "foil_common.gdshaderinc"

uniform int foil_type : hint_range(0, 2) = 0;  // 0=none, 1=regular, 2=etched
uniform float shimmer_speed : hint_range(0.1, 5.0) = 1.0;
uniform float foil_intensity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    if (foil_type == 0) return;  // Non-foil
    
    float time = TIME * shimmer_speed;
    vec2 uv = UV;
    float foil_mask = 0.0;
    vec3 foil_color = vec3(0.0);
    
    if (foil_type == 1) {
        // Regular foil logic via include
    } else if (foil_type == 2) {
        // Etched foil logic via include
    }
    
    // Blend foil effect
    COLOR.rgb = mix(COLOR.rgb, foil_color, foil_intensity * foil_mask);
}
```

## Data Model Changes

### CardMetadata
Add `foil_type: int` property:
- 0 = non-foil
- 1 = regular foil
- 2 = etched foil

Default: 0 (non-foil)

## Integration

### CardView Changes
1. Add child FxSubViewport with FoilOverlay
2. Pass `metadata.foil_type` to foil shader uniform
3. FxSubViewport renders on top of card texture
4. Use `FOLDOUT_BLACK` or `FOLDOUT_DISABLED` blend mode for proper compositing

### FoilOverlay Node
- Transparent background
- ShaderMaterial with foil_base.gdshader
- Size matches card dimensions
- Receives mouse events disabled (pass-through)

## Shader Parameters (Exposed)

| Parameter | Type | Range | Default | Description |
|-----------|------|-------|---------|-------------|
| foil_type | int | 0-2 | 0 | Foil treatment type |
| shimmer_speed | float | 0.1-5.0 | 1.0 | Animation speed |
| foil_intensity | float | 0.0-1.0 | 0.8 | Effect strength |

## Implementation Phases

### Phase 1: Shader Foundation
- Create `shaders/cards/foil/` directory
- Implement `foil_common.gdshaderinc` with noise functions
- Implement `foil_regular.gdshaderinc` with rainbow effect
- Implement `foil_etched.gdshaderinc` with metallic effect
- Create `foil_base.gdshader` with type switching

### Phase 2: Scene Structure  
- Create `scenes/card/foil/foil_layer.tscn`
- Set up FxSubViewport + FoilOverlay ColorRect
- Apply shader material
- Test standalone

### Phase 3: Data Integration
- Add `foil_type` to `CardMetadata`
- Wire up foil application in `CardView._ready()`

### Phase 4: Polish
- Expose shader parameters for tweaking
- Test all three foil types visually
- Verify performance impact

## Technical Notes

- SubViewport isolation ensures foil shader doesn't affect card image shader
- `.gdshaderinc` files are included at compile-time, not runtime
- Static effect means no continuous animation unless time uniform is used
- Consider adding mouse position uniform for angle-based shimmer enhancement

## Out of Scope

- Animated foil variants (full shimmer animation)
- Showcase/borderless special treatments
- Dynamic foil switching at runtime (future enhancement)
- Multiple foil layers (rainbow + etched combo)
