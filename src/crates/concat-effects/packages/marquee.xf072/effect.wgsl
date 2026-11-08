fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let m = select(0.0, 1.0, abs(uv.x - 0.5) < progress * 0.5 || abs(uv.y - 0.5) < progress * 0.5);
    return mix(from_at(uv), to_at(uv), m);
}
