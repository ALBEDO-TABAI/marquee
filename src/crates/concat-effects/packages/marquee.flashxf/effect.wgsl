// 闪光切: a cut under a short white flash.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A hard cut under a short, blinding flash.
    let base = select(from_at(uv), to_at(uv), p >= 0.5);
    let x = (p - 0.5) / 0.05;
    let flash = exp(-x * x) * 2.5;
    return vec4<f32>(base.rgb + vec3<f32>(flash), base.a);
}
