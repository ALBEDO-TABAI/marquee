fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = smoothstep(0.0, 1.0, progress);
    let dir = normalize(uv - vec2<f32>(0.5) + vec2<f32>(1e-4));
    let s = 1.00 * 0.03 * (1.0 - abs(t * 2.0 - 1.0));
    let a = (from_at(uv) + from_at(uv + dir * s) + from_at(uv - dir * s)) / 3.0;
    let b = (to_at(uv) + to_at(uv + dir * s) + to_at(uv - dir * s)) / 3.0;
    return mix(a, b, t);
}
