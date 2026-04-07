#include "foil_common.gdshaderinc"

void regular_foil(in vec2 uv, in float time, out vec3 foil_color, out float foil_mask) {
    float hue = uv.x + uv.y * 0.5 + time * 0.1;
    hue = fract(hue);
    
    float r = abs(hue * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(hue * 6.0 - 2.0);
    float b = 2.0 - abs(hue * 6.0 - 4.0);
    foil_color = clamp(vec3(r, g, b), 0.0, 1.0);
    
    float edge = fresnel(uv, 0.8);
    edge = pow(edge, 0.5);
    
    float shimmer = fbm(uv * 15.0 + time * 0.3, 4);
    shimmer = smoothstep(0.3, 0.7, shimmer);
    
    float interference = sin(uv.x * 30.0 + time) * sin(uv.y * 30.0 - time);
    interference = interference * 0.5 + 0.5;
    
    foil_mask = edge * (0.4 + shimmer * 0.4 + interference * 0.2);
    foil_mask = clamp(foil_mask, 0.0, 1.0);
}
