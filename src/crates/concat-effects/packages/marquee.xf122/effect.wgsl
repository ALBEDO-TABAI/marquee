fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = smoothstep(0.0, 1.0, progress);
    return mix(from_at(uv), to_at(uv), t);
}
