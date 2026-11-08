fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let outgoing = progress < 0.5;
    let frame = select(to_at(uv), from_at(uv), outgoing);
    let dip = 1.0 - abs(progress * 2.0 - 1.0);
    let rgb = from_display(to_display(frame.rgb) * (1.0 - dip) + vec3<f32>(1.0) * dip);
    return vec4<f32>(rgb, frame.a);
}
