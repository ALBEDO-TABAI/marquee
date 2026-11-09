// 跳接: a cut that lands a step tighter.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A jump cut: the same framing a step tighter after the cut.
    let after = p >= 0.5;
    let q = (uv - vec2<f32>(0.5)) / 1.08 + vec2<f32>(0.5);
    return select(from_at(uv), to_at(q), after);
}
