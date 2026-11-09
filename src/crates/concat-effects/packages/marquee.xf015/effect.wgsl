// 基础硬切感: a near-cut with the edge just taken off.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Nearly a cut: the change takes a tenth of the transition.
    return mix(from_at(uv), to_at(uv), smoothstep(0.45, 0.55, p));
}
