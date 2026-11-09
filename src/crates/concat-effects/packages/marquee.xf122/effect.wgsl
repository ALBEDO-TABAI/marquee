// 口播种切: a punch-in cut that eases back.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A talking-head cut: in on the next shot, easing back out.
    let after = p >= 0.5;
    let z = mix(1.1, 1.0, smoothstep(0.5, 1.0, p));
    let q = (uv - vec2<f32>(0.5)) / z + vec2<f32>(0.5);
    return select(from_at(uv), to_at(q), after);
}
