// 滑入: the next picture slides in from the right.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // The incoming picture slides in from the right over the outgoing one.
    let s = smoothstep(0.0, 1.0, p);
    let x = uv.x - (1.0 - s);
    let shade = 1.0 - 0.25 * s;
    let behind = from_at(uv);
    return select(vec4<f32>(behind.rgb * shade, behind.a), to_at(vec2<f32>(x, uv.y)), x >= 0.0);
}
