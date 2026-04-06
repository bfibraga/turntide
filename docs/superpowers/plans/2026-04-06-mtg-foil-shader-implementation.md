# MTG Card Foil Shader System - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement foil shader effects (non-foil, regular, etched) for MTG cards using layered SubViewport with `.gdshaderinc` includes.

**Architecture:** Layered shader system with shared includes for foil math, separate effect variants for regular rainbow foil and etched metallic foil, integrated via SubViewport overlay.

**Tech Stack:** Godot 4.6, GDScript, GLSL (.gdshader/.gdshaderinc)

---

## File Structure

```
client/
├── shaders/cards/foil/
│   ├── foil_common.gdshaderinc      # Noise functions, UV helpers
│   ├── foil_regular.gdshaderinc     # Rainbow holographic effect  
│   ├── foil_etched.gdshaderinc      # Metallic specular effect
│   └── foil_base.gdshader          # Main shader with type switching
│
├── scenes/card/foil/
│   └── foil_layer.tscn              # FxSubViewport + ColorRect scene
│
└── scripts/card/
    ├── foil_overlay.gd              # Script for FoilOverlay node
    └── view.gd                      # Modify to apply foil
```

---

## Task 1: Create Shader Foundation - foil_common.gdshaderinc

**Files:**
- Create: `client/shaders/cards/foil/foil_common.gdshaderinc`

- [ ] **Step 1: Create foil_common.gdshaderinc with noise functions**

```glsl
// foil_common.gdshaderinc - Shared utilities for all foil types

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * smoothNoise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

float fresnel(vec2 uv, float power) {
    vec2 center = uv - 0.5;
    float dist = length(center);
    return pow(dist, power);
}

vec2 distortUV(vec2 uv, float time, float strength) {
    float noise = smoothNoise(uv * 10.0 + time * 0.5);
    return uv + vec2(noise - 0.5, noise - 0.5) * strength;
}
```

- [ ] **Step 2: Commit**

```bash
git add client/shaders/cards/foil/foil_common.gdshaderinc
git commit -m "shader: add foil_common.gdshaderinc with noise utilities"
```

---

## Task 2: Create Regular Foil Shader - foil_regular.gdshaderinc

**Files:**
- Create: `client/shaders/cards/foil/foil_regular.gdshaderinc`

- [ ] **Step 1: Create foil_regular.gdshaderinc with rainbow holographic effect**

```glsl
// foil_regular.gdshaderinc - Rainbow holographic foil effect

void regular_foil(in vec2 uv, in float time, out vec3 foil_color, out float foil_mask) {
    // Rainbow spectrum based on UV position
    float hue = uv.x + uv.y * 0.5 + time * 0.1;
    hue = fract(hue);
    
    // Convert hue to RGB (rainbow)
    float r = abs(hue * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(hue * 6.0 - 2.0);
    float b = 2.0 - abs(hue * 6.0 - 4.0);
    foil_color = clamp(vec3(r, g, b), 0.0, 1.0);
    
    // Edge emphasis via fresnel
    float edge = fresnel(uv, 0.8);
    edge = pow(edge, 0.5);
    
    // Shimmer via noise
    float shimmer = fbm(uv * 15.0 + time * 0.3, 4);
    shimmer = smoothstep(0.3, 0.7, shimmer);
    
    // Interference pattern
    float interference = sin(uv.x * 30.0 + time) * sin(uv.y * 30.0 - time);
    interference = interference * 0.5 + 0.5;
    
    // Combine effects
    foil_mask = edge * (0.4 + shimmer * 0.4 + interference * 0.2);
    foil_mask = clamp(foil_mask, 0.0, 1.0);
}
```

- [ ] **Step 2: Commit**

```bash
git add client/shaders/cards/foil/foil_regular.gdshaderinc
git commit -m "shader: add foil_regular.gdshaderinc with rainbow holographic effect"
```

---

## Task 3: Create Etched Foil Shader - foil_etched.gdshaderinc

**Files:**
- Create: `client/shaders/cards/foil/foil_etched.gdshaderinc`

- [ ] **Step 1: Create foil_etched.gdshaderinc with metallic specular effect**

```glsl
// foil_etched.gdshaderinc - Metallic etched foil effect

void etched_foil(in vec2 uv, in float time, out vec3 foil_color, out float foil_mask) {
    // Metallic specular highlight
    vec2 center = uv - 0.5;
    float dist = length(center);
    
    // Specular from top-right
    vec2 lightDir = normalize(vec2(0.5, 0.5));
    vec2 toCenter = normalize(center);
    float spec = dot(lightDir, toCenter);
    spec = pow(max(spec, 0.0), 8.0);
    
    // Coarser noise pattern (larger scale than regular foil)
    float noise = fbm(uv * 5.0 + time * 0.1, 3);
    noise = smoothstep(0.2, 0.8, noise);
    
    // Subtle gleam animation
    float gleam = sin(noise * 6.28 + time * 0.5);
    gleam = gleam * 0.5 + 0.5;
    
    // Metallic color (silver/gold tones)
    foil_color = vec3(0.8, 0.8, 0.85); // Silver base
    float warmth = fbm(uv * 3.0, 2) * 0.2;
    foil_color += vec3(warmth, warmth * 0.8, 0.0); // Slight gold tint
    
    // Softer edge response
    float edge = fresnel(uv, 1.2);
    edge = pow(edge, 0.7);
    
    // Combine effects
    foil_mask = (spec * 0.6 + noise * 0.3 + gleam * 0.1) * edge;
    foil_mask = clamp(foil_mask, 0.0, 1.0);
}
```

- [ ] **Step 2: Commit**

```bash
git add client/shaders/cards/foil/foil_etched.gdshaderinc
git commit -m "shader: add foil_etched.gdshaderinc with metallic specular effect"
```

---

## Task 4: Create Main Foil Shader - foil_base.gdshader

**Files:**
- Create: `client/shaders/cards/foil/foil_base.gdshader`

- [ ] **Step 1: Create foil_base.gdshader with type switching**

```gdshader
shader_type canvas_item;

#include "res://shaders/cards/foil/foil_common.gdshaderinc"

uniform int foil_type : hint_range(0, 2) = 0;  // 0=none, 1=regular, 2=etched
uniform float shimmer_speed : hint_range(0.1, 5.0) = 1.0;
uniform float foil_intensity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    vec4 texColor = texture(TEXTURE, UV);
    
    // Non-foil: return original color
    if (foil_type == 0) {
        COLOR = texColor;
        return;
    }
    
    vec2 uv = UV;
    float time = TIME * shimmer_speed;
    vec3 foil_color = vec3(0.0);
    float foil_mask = 0.0;
    
    if (foil_type == 1) {
        #include "res://shaders/cards/foil/foil_regular.gdshaderinc"
        regular_foil(uv, time, foil_color, foil_mask);
    } else if (foil_type == 2) {
        #include "res://shaders/cards/foil/foil_etched.gdshaderinc"
        etched_foil(uv, time, foil_color, foil_mask);
    }
    
    // Blend foil effect with original
    COLOR = vec4(mix(texColor.rgb, foil_color, foil_mask * foil_intensity), texColor.a);
}
```

- [ ] **Step 2: Commit**

```bash
git add client/shaders/cards/foil/foil_base.gdshader
git commit -m "shader: add foil_base.gdshader with foil type switching"
```

---

## Task 5: Create Foil Layer Scene

**Files:**
- Create: `client/scenes/card/foil/foil_layer.tscn`

- [ ] **Step 1: Create foil_layer.tscn scene structure**

```tscn
[gd_scene format=3 uid="uid://foil_layer_unique"]

[ext_resource type="Shader" uid="uid://foil_base_unique" path="res://shaders/cards/foil/foil_base.gdshader" id="1_foil"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_foil"]
resource_local_to_scene = true
shader = ExtResource("1_foil")
shader_parameter/foil_type = 0
shader_parameter/shimmer_speed = 1.0
shader_parameter/foil_intensity = 0.8

[node name="FxSubViewport" type="SubViewport"]
transparent_bg = true
handle_input_locally = false
size = Vector2i(250, 350)
render_target_update_mode = 4

[node name="FoilOverlay" type="ColorRect" parent="FxSubViewport" unique_name_owner=1]
material = SubResource("ShaderMaterial_foil")
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2  # MOUSE_FILTER_IGNORE
```

- [ ] **Step 2: Verify scene can be added to project**

Open Godot editor and verify scene loads without errors.

- [ ] **Step 3: Commit**

```bash
git add client/scenes/card/foil/foil_layer.tscn
git commit -m "scene: add foil_layer.tscn SubViewport + ColorRect"
```

---

## Task 6: Create FoilOverlay Script

**Files:**
- Create: `client/scripts/card/foil_overlay.gd`

- [ ] **Step 1: Create foil_overlay.gd script**

```gdscript
class_name FoilOverlay
extends ColorRect

@export var foil_type: int = 0:
    set(value):
        foil_type = value
        _update_foil_type()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _update_foil_type()

func _update_foil_type() -> void:
    if material is ShaderMaterial:
        material.set_shader_parameter("foil_type", foil_type)

func set_intensity(intensity: float) -> void:
    if material is ShaderMaterial:
        material.set_shader_parameter("foil_intensity", intensity)

func set_speed(speed: float) -> void:
    if material is ShaderMaterial:
        material.set_shader_parameter("shimmer_speed", speed)
```

- [ ] **Step 2: Commit**

```bash
git add client/scripts/card/foil_overlay.gd
git commit -m "script: add foil_overlay.gd for foil parameter control"
```

---

## Task 7: Integrate Foil into CardView

**Files:**
- Modify: `client/scripts/card/view.gd`
- Modify: `client/scenes/card/card_view.tscn`

- [ ] **Step 1: Update CardView to include foil layer**

Modify `client/scripts/card/view.gd` to add:

```gdscript
class_name CardView extends Control

var metadata: CardMetadata
var foil_overlay: FoilOverlay

@onready var card_texture: CardTexture = $SubViewportContainer/SubViewport/TextureRect

func _ready() -> void:
    if not metadata: return
    
    # Existing code...
    Global.printings_manager.card_printing_ready.connect(_on_image_became_available)
    
    if info.status == "ready":
        _start_async_texture_load(info.path)
    else:
        self.modulate = Color(0.3, 0.3, 0.3)
        Global.printings_manager.request_download(metadata)
    
    # Add foil layer
    _setup_foil_layer()

func _setup_foil_layer() -> void:
    var foil_scene = preload("res://scenes/card/foil/foil_layer.tscn")
    var foil_instance = foil_scene.instantiate()
    foil_instance.size = Vector2(250, 350)
    
    # Get the FoilOverlay node
    foil_overlay = foil_instance.get_node("FoilOverlay")
    
    # Add to SubViewport
    $SubViewportContainer.add_child(foil_instance)
    
    # Set foil type from metadata
    if metadata.foil_type > 0:
        foil_overlay.foil_type = metadata.foil_type
```

- [ ] **Step 2: Update card_view.tscn to ensure proper layer order**

Ensure SubViewportContainer children render in correct order (TextureRect first, then foil overlay).

- [ ] **Step 3: Commit**

```bash
git add client/scripts/card/view.gd client/scenes/card/card_view.tscn
git commit -m "feat: integrate foil overlay into CardView"
```

---

## Task 8: Add Foil Type to CardMetadata

**Files:**
- Modify: `client/scripts/database/models/card_metadata.gd`

- [ ] **Step 1: Add foil_type property to CardMetadata**

```gdscript
class_name CardMetadata 
extends RefCounted

var uuid: String = ""
var name: String = ""
var setcode: String = ""
var number: String = ""
var rarity: String = ""
var type_line: String = ""
var mana_value: float = .0
var colors: String = ""
var text: String = ""
var power: String = ""
var toughness: String = ""
var scryfall_id: String = ""
var foil_type: int = 0  # 0=none, 1=regular, 2=etched

func _init(
    # ... existing params ...
    foil_type: int = 0,
) -> void:
    # ... existing assignments ...
    self.foil_type = foil_type
```

- [ ] **Step 2: Update from_dict to include foil_type**

```gdscript
static func from_dict(data: Dictionary) -> CardMetadata:
    return CardMetadata.new(
        # ... existing params ...
        data.get("foil_type", 0),
    )
```

- [ ] **Step 3: Update to_dict to include foil_type**

```gdscript
func to_dict() -> Dictionary:
    return {
        # ... existing fields ...
        "foil_type": self.foil_type,
    }
```

- [ ] **Step 4: Commit**

```bash
git add client/scripts/database/models/card_metadata.gd
git commit -m "feat: add foil_type property to CardMetadata"
```

---

## Task 9: Polish and Testing

**Files:**
- Test manually in Godot editor

- [ ] **Step 1: Test non-foil cards display correctly**

Load a card with `foil_type = 0` and verify no visual effect.

- [ ] **Step 2: Test regular foil cards display rainbow effect**

Load a card with `foil_type = 1` and verify rainbow holographic shimmer.

- [ ] **Step 3: Test etched foil cards display metallic effect**

Load a card with `foil_type = 2` and verify metallic specular effect.

- [ ] **Step 4: Adjust shader parameters if needed**

Tweak `shimmer_speed` and `foil_intensity` for desired effect strength.

- [ ] **Step 5: Commit final adjustments**

```bash
git add -A
git commit -m "chore: foil shader final polish"
```

---

## Verification Checklist

After implementation, verify:
- [ ] Non-foil cards show no foil effect
- [ ] Regular foil cards show rainbow holographic shimmer
- [ ] Etched foil cards show metallic specular effect
- [ ] Foil effect is static (not animated)
- [ ] Foil intensity uniform affects effect strength
- [ ] All files compile without errors in Godot editor
