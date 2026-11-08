fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    if (t < 0.5) {
        return mix(from_at(uv), vec4<f32>(0.0, 0.0, 0.0, 1.0), t * 2.0);
    }
    return mix(vec4<f32>(0.0, 0.0, 0.0, 1.0), to_at(uv), (t - 0.5) * 2.0);
}
