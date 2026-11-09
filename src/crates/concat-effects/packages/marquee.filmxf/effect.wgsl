// 胶片叠化: a dissolve with projector flicker and grain.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A dissolve that flickers and grains like a projected print.
    let t = smoothstep(0.0, 1.0, p);
    let base = mix(from_at(uv), to_at(uv), t);
    let mid = sin(3.14159265 * p);
    let flicker = 1.0 + 0.25 * mid * (hash(vec2<f32>(floor(p * 24.0), 7.0), 3.0) - 0.5);
    let grain = (hash(floor(uv * frame.size), floor(p * 24.0)) - 0.5) * 0.12 * mid;
    return vec4<f32>(base.rgb * flicker + vec3<f32>(grain), base.a);
}
