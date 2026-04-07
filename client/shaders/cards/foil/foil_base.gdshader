shader_type canvas_item;

#include "res://shaders/cards/foil/foil_common.gdshaderinc"
#include "res://shaders/cards/foil/foil_regular.gdshaderinc"
#include "res://shaders/cards/foil/foil_etched.gdshaderinc"

uniform int foil_type : hint_range(0, 2) = 0;
uniform float shimmer_speed : hint_range(0.1, 5.0) = 1.0;
uniform float foil_intensity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    vec4 texColor = texture(TEXTURE, UV);
    
    if (foil_type == 0) {
        COLOR = texColor;
        discard;
    }
    
    vec2 uv = UV;
    float time = TIME * shimmer_speed;
    vec3 foil_color = vec3(0.0);
    float foil_mask = 0.0;
    
    if (foil_type == 1) {
        regular_foil(uv, time, foil_color, foil_mask);
    } else if (foil_type == 2) {
        etched_foil(uv, time, foil_color, foil_mask);
    }
    
    COLOR = vec4(mix(texColor.rgb, foil_color, foil_mask * foil_intensity), texColor.a);
}
