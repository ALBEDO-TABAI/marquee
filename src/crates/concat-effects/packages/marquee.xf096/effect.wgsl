// 硬切: a straight cut at the middle.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    return select(from_at(uv), to_at(uv), p >= 0.5);
}
