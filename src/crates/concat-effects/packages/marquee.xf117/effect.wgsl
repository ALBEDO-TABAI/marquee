fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let m = smoothstep(0.9 * (1.0 - t) - 0.04, 0.9 * (1.0 - t) + 0.04, length(uv - vec2<f32>(0.5)) / (0.7 + 0.3 * abs(cos(atan2(uv.y - 0.5, uv.x - 0.5) * 5.0))));
    return mix(from_at(uv), to_at(uv), clamp(m, 0.0, 1.0));
}
