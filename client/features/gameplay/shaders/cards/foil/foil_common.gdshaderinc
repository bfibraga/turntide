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
