fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let m = 1.0 - smoothstep(1.0 * t - 0.04, 1.0 * t + 0.04, (abs(uv.x - 0.5) + abs(uv.y - 0.5)));
    return mix(from_at(uv), to_at(uv), clamp(m, 0.0, 1.0));
}
