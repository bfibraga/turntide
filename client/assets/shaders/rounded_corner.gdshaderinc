group_uniforms CornerSettings;
uniform float corner_tl : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float corner_tr : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float corner_bl : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float corner_br : hint_range(0.0, 1.0, 0.1) = 0.0;

float sdRoundBox(vec2 p, vec2 b, vec4 r) {
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x  = (p.y > 0.0) ? r.x  : r.y;
    vec2 q = abs(p) - b + r.x;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r.x;
}

bool isCornerDiscarded(vec2 uv) {
    vec4 r = vec4(corner_br, corner_tr, corner_bl, corner_tl) / 2.0;
    if (max(max(r.x, r.y), max(r.z, r.w)) <= 0.0) return false;
    vec2 p = uv - 0.5;
    return sdRoundBox(p, vec2(0.5), r) > 0.0;
}
