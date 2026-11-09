// 地图推近: a deep push in that lands on the next picture.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Pushed deep into the outgoing picture, then out of the incoming.
    let z1 = 1.0 + 2.0 * p * p;
    let z2 = mix(1.8, 1.0, smoothstep(0.3, 1.0, p));
    let a = from_at((uv - vec2<f32>(0.5)) / z1 + vec2<f32>(0.5));
    let b = to_at((uv - vec2<f32>(0.5)) / z2 + vec2<f32>(0.5));
    return mix(a, b, smoothstep(0.4, 0.85, p));
}
