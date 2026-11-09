fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let black = vec4<f32>(0.0, 0.0, 0.0, 1.0);
    // Down to black by 40%, held to 60%, then up into the next shot.
    if (t < 0.5) {
        return mix(from_at(uv), black, smoothstep(0.0, 0.4, t));
    }
    return mix(black, to_at(uv), smoothstep(0.6, 1.0, t));
}
