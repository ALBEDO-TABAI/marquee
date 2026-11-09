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
// 心动描边: a neon heart outline around the picture, beating, the outside dimmed.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = fract(t * 1.1);
    let beat = 1.0 + 0.05 * exp(-ph * 9.0) + 0.03 * exp(-abs(ph - 0.22) * 25.0);
    let d = heart_at(p, vec2<f32>(0.5 * aspect, 0.5), 0.92 * beat);
    let line = exp(-abs(d) * frame.size.y * 0.25);
    let glow = exp(-abs(d) * 22.0) * 0.6;
    let outside = smoothstep(-0.005, 0.01, d);
    let pink = vec3<f32>(1.0, 0.3, 0.6);
    let look = c.rgb * (1.0 - outside * 0.55) + pink * outside * 0.12 + pink * (line * 1.4 + glow);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
