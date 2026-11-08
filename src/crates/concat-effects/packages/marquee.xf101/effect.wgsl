fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let line = select(0.0, 1.0, fract(uv.y * 90.0) < 0.45);
    let src = mix(from_at(uv), to_at(uv), t);
    return vec4<f32>(src.rgb * (0.75 + 0.25 * line), src.a);
}
