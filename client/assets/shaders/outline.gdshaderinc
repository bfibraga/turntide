group_uniforms OutlineSettings;
uniform vec4 outline_color : source_color = vec4(1.0);
uniform float width : hint_range(0, 10) = 1.0;
uniform int pattern : hint_range(0, 2) = 0;
uniform bool inside = false;
uniform bool add_margins = true;

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	for (float i = -ceil(width); i <= ceil(width); i++) {
		float x = abs(i) > width ? width * sign(i) : i;
		float offset;
		
		if (pattern == 0) {
			offset = width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = width;
		}
		
		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);
			
			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == inside) {
				return true;
			}
		}
	}
	
	return false;
}

bool isOutlinePixel(vec2 uv, sampler2D sample_texture, vec2 texture_pixel_size) {
	vec4 texel = texture(sample_texture, uv);
	return (texel.a > 0.0) == inside && hasContraryNeighbour(uv, texture_pixel_size, sample_texture);
}

vec4 applyOutlineColor(vec4 base_color) {
	vec4 result = base_color;
	result.rgb = inside ? mix(base_color.rgb, outline_color.rgb, outline_color.a) : outline_color.rgb;
	result.a += (1.0 - base_color.a) * outline_color.a;
	return result;
}

void setup_margins(inout vec2 vertex, vec2 uv) {
	if (add_margins) {
		vertex += (uv * 2.0 - 1.0) * width;
	}
}
