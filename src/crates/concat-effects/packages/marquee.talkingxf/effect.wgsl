fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    // The outgoing shot pushes in a little, the cut lands at the middle,
    // and the incoming shot eases back out from the same push - the way a
    // jump cut on a talking head is smoothed.
    let z_out = 1.0 + 0.08 * smoothstep(0.0, 0.5, t);
    let z_in = 1.0 + 0.08 * (1.0 - smoothstep(0.5, 1.0, t));
    let a = from_at((uv - vec2<f32>(0.5)) / z_out + vec2<f32>(0.5));
    let b = to_at((uv - vec2<f32>(0.5)) / z_in + vec2<f32>(0.5));
    return mix(a, b, smoothstep(0.42, 0.58, t));
}
