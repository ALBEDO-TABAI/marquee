// 划痕切: a cut under flickering film scratches.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A scratched cut: film scratches flicker across the change.
    let mid = sin(3.14159265 * p);
    let col = floor(uv.x * 160.0);
    let scratch = step(0.97, hash(vec2<f32>(col, 3.0), floor(p * 24.0))) * mid;
    let base = select(from_at(uv), to_at(uv), p >= 0.5);
    return vec4<f32>(mix(base.rgb, vec3<f32>(0.95), scratch * 0.8), base.a);
}
