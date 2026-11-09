fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let a = from_at(uv);
    let b = to_at(uv);
    let t = smoothstep(0.0, 1.0, progress);
    return mix(a, b, t);
}
