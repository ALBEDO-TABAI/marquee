// 智能叠化: a dissolve led by the picture's light.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Dissolve in order of brightness: the light parts change first.
    let a = from_at(uv);
    let order = 1.0 - clamp(luma(a.rgb), 0.0, 1.0);
    let m = smoothstep(order - 0.15, order + 0.15, p * 1.3 - 0.15);
    return mix(a, to_at(uv), m);
}
