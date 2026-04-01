shader_type canvas_item;

uniform float _cornerRadius : hint_range(0., 100.) = 0.; 

float roundedBoxSDF(vec2 uv, vec2 size, float radius){
	vec2 d = abs(uv - 0.5) * 2.0 - size + radius;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 texColor = texture(TEXTURE, UV);
	
	if(_cornerRadius > 0.0){
		float radiusUV = _cornerRadius * TEXTURE_PIXEL_SIZE.x;
		float dist = roundedBoxSDF(UV, vec2(1.0), radiusUV);
		if(dist > 0.0){
			discard;
		}
	}
	
	COLOR = texColor;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
