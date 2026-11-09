fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let edge = uv.y;
    // 5: a feather 5% of the frame wide, at an even pace.
    let w = 0.050;
    let t = clamp(progress, 0.0, 1.0);
    // The soft band starts wholly off one side and ends wholly off the
    // other, so the first frame is all outgoing and the last all incoming.
    let p = mix(-0.5 * w, 1.0 + 0.5 * w, t);
    let m = smoothstep(p - 0.5 * w, p + 0.5 * w, edge);
    return mix(to_at(uv), from_at(uv), m);
}
