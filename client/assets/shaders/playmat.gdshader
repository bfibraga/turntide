shader_type canvas_item;

#include "rounded_corner.gdshaderinc"
#include "outline.gdshaderinc"

void vertex() {
	setup_margins(VERTEX, UV);
}

void fragment() {
	if (isOutlinePixel(UV, TEXTURE, TEXTURE_PIXEL_SIZE)) COLOR = applyOutlineColor(COLOR);
    
	vec4 image = texture(TEXTURE, UV);
    if (isCornerDiscarded(UV)) image.a = 0.0;
    
	COLOR = image;
}