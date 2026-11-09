// 新潮闪切: a double strobe and a punched-in cut.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Two strobes around a punched-in cut.
    let a1 = (p - 0.38) / 0.035;
    let a2 = (p - 0.58) / 0.035;
    let flash = (exp(-a1 * a1) + exp(-a2 * a2)) * 2.5;
    let after = p >= 0.48;
    let punch = select(1.0, mix(1.12, 1.0, smoothstep(0.48, 0.9, p)), after);
    let q = (uv - vec2<f32>(0.5)) / punch + vec2<f32>(0.5);
    let base = select(from_at(uv), to_at(q), after);
    return vec4<f32>(base.rgb + vec3<f32>(flash), base.a);
}
