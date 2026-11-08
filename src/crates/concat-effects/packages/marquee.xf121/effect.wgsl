fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let m = smoothstep(0.72 * (1.0 - t) - 0.04, 0.72 * (1.0 - t) + 0.04, max(abs(uv.x - 0.5), abs(uv.y - 0.5)));
    return mix(from_at(uv), to_at(uv), clamp(m, 0.0, 1.0));
}
