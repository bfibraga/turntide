shader_type canvas_item;

uniform vec2 offset = vec2(10.0, 0.0);

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int num_cards : hint_range(1, 10) = 5;

void vertex() {
	VERTEX = VERTEX + offset * progress;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 col = texture(TEXTURE, base_uv - offset * progress);
	
    COLOR = col;
}
