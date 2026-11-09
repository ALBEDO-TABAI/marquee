// 分割: the picture splits and its halves part.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // The outgoing picture splits along the middle and its halves part.
    let s = smoothstep(0.0, 1.0, p) * 0.5;
    if (uv.y < 0.5) {
        let y = uv.y + s;
        return select(to_at(uv), from_at(vec2<f32>(uv.x, y)), y < 0.5);
    }
    let y = uv.y - s;
    return select(to_at(uv), from_at(vec2<f32>(uv.x, y)), y >= 0.5);
}
