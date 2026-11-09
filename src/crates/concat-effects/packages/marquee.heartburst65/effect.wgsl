struct Params { amount: f32 }
// A heart's signed distance, tip at the origin and the lobes about y = 1,
// y up: inside is negative.
fn heart_d(q: vec2<f32>) -> f32 {
    let h = vec2<f32>(abs(q.x), q.y);
    if (h.y + h.x > 1.0) {
        return length(h - vec2<f32>(0.25, 0.75)) - 0.35355;
    }
    let m = h - vec2<f32>(0.0, 1.0);
    let n = h - vec2<f32>(0.5 * max(h.x + h.y, 0.0));
    return sqrt(min(dot(m, m), dot(n, n))) * sign(h.x - h.y);
}
// The heart `size` tall centred at `at`, both in the picture's square units.
fn heart_at(p: vec2<f32>, at: vec2<f32>, size: f32) -> f32 {
    let q = (p - at) / size;
    return heart_d(vec2<f32>(q.x, 0.55 - q.y) * 1.1) * size;
}
// 爱心绽放: a burst of hearts flying out from the middle, again and again.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(1.6);
    let mid = vec2<f32>(0.5 * aspect, 0.52);
    var over = vec3<f32>(0.0);
    var cover = 0.0;
    for (var i = 0; i < 14; i++) {
        let k = f32(i);
        let dir = vec2<f32>(cos(k * 2.39996 + 0.3), sin(k * 2.39996 + 0.3));
        let reach = (0.18 + 0.32 * fract(k * 0.618)) * (1.0 - pow(1.0 - ph, 3.0));
        let at = mid + dir * reach;
        let size = (0.05 + 0.04 * fract(k * 0.37)) * (0.3 + 0.7 * min(ph * 4.0, 1.0));
        let fade = 1.0 - smoothstep(0.9, 1.0, ph);
        let d = heart_at(p, at, size);
        let inside = (1.0 - smoothstep(-0.002, 0.003, d)) * fade;
        let col = mix(vec3<f32>(1.0, 0.25, 0.45), vec3<f32>(1.0, 0.6, 0.75), fract(k * 0.43));
        over = mix(over, col, inside);
        cover = max(cover, inside);
        cover = max(cover, exp(-max(d, 0.0) * 90.0) * 0.35 * fade);
    }
    let look = mix(c.rgb, max(over, vec3<f32>(1.0, 0.5, 0.65) * 0.9), cover);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
