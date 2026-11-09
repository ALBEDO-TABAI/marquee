// 立方翻转: a cube turns from one face to the next.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A cube turning left: the outgoing face narrows away, the incoming
    // one widens in, each shaded by its angle.
    let s = smoothstep(0.0, 1.0, p);
    let edge = 1.0 - s;
    if (uv.x < edge) {
        let x = uv.x / max(edge, 1e-4);
        let squeeze = 1.0 + 0.2 * s * x;
        let y = (uv.y - 0.5) * squeeze + 0.5;
        let c = from_at(vec2<f32>(x, y));
        let inside = select(0.0, 1.0, y >= 0.0 && y <= 1.0);
        return vec4<f32>(c.rgb * (1.0 - 0.5 * s) * inside, c.a);
    }
    let x = (uv.x - edge) / max(s, 1e-4);
    let squeeze = 1.0 + 0.2 * (1.0 - s) * (1.0 - x);
    let y = (uv.y - 0.5) * squeeze + 0.5;
    let c = to_at(vec2<f32>(x, y));
    let inside = select(0.0, 1.0, y >= 0.0 && y <= 1.0);
    return vec4<f32>(c.rgb * (0.5 + 0.5 * s) * inside, c.a);
}
