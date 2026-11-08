fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let tear = step(0.5, fract(uv.y * 8.0 + t * 3.0)) * 0.04 * (1.0 - abs(t * 2.0 - 1.0));
    return mix(from_at(uv + vec2<f32>(tear, 0.0)), to_at(uv - vec2<f32>(tear, 0.0)), t);
}
