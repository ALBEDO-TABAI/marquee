// 光斑切: a lens flare crosses and the cut hides under it.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A bright flare crosses the frame; the cut hides under it.
    let centre = mix(vec2<f32>(-0.2, 0.35), vec2<f32>(1.2, 0.65), p);
    let d = distance(uv, centre);
    let peak = sin(3.14159265 * p);
    let glow = peak * (exp(-d * d * 22.0) * 1.1 + exp(-abs(uv.y - centre.y) * 30.0) * 0.25);
    let base = select(from_at(uv), to_at(uv), p >= 0.5);
    return vec4<f32>(base.rgb + vec3<f32>(1.0, 0.85, 0.6) * glow, base.a);
}
