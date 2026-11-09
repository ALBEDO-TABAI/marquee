// 矩形打开: a rectangle opens from the middle.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A rectangle the shape of the frame opens from the middle.
    let d = max(abs(uv.x - 0.5), abs(uv.y - 0.5)) * 2.0;
    let m = 1.0 - smoothstep(p * 1.04 - 0.02, p * 1.04 + 0.0, d);
    return mix(from_at(uv), to_at(uv), m);
}
