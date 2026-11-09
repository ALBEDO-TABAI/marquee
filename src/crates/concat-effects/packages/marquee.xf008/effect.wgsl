fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    // Basic: an even, linear mix - no easing.
    return mix(from_at(uv), to_at(uv), clamp(progress, 0.0, 1.0));
}
