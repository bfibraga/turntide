#include "foil_common.gdshaderinc"

void etched_foil(in vec2 uv, in float time, out vec3 foil_color, out float foil_mask) {
    vec2 center = uv - 0.5;
    float dist = length(center);
    
    vec2 lightDir = normalize(vec2(0.5, 0.5));
    vec2 toCenter = normalize(center);
    float spec = dot(lightDir, toCenter);
    spec = pow(max(spec, 0.0), 8.0);
    
    float noise = fbm(uv * 5.0 + time * 0.1, 3);
    noise = smoothstep(0.2, 0.8, noise);
    
    float gleam = sin(noise * 6.28 + time * 0.5);
    gleam = gleam * 0.5 + 0.5;
    
    foil_color = vec3(0.8, 0.8, 0.85);
    float warmth = fbm(uv * 3.0, 2) * 0.2;
    foil_color += vec3(warmth, warmth * 0.8, 0.0);
    
    float edge = fresnel(uv, 1.2);
    edge = pow(edge, 0.7);
    
    foil_mask = (spec * 0.6 + noise * 0.3 + gleam * 0.1) * edge;
    foil_mask = clamp(foil_mask, 0.0, 1.0);
}
