// 形状打开: a diamond opens onto the next picture.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A diamond opens from the middle.
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let q = abs(uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    let d = (q.x + q.y) / (0.5 * aspect + 0.5);
    let m = 1.0 - smoothstep(p * 1.05 - 0.04, p * 1.05 + 0.01, d);
    return mix(from_at(uv), to_at(uv), m);
}
