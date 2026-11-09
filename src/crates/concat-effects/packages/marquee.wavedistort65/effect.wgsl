struct Params { amount: f32 }
// 波纹畸变: rings of ripples running out from the middle.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    let r = length(d);
    let wave = sin(r * 42.0 - t * 6.0) * 0.012 * a * smoothstep(0.0, 0.1, r);
    let q = uv + normalize(d + vec2<f32>(1e-5)) / vec2<f32>(aspect, 1.0) * wave;
    let s = sample(q);
    return vec4<f32>(s.rgb * (1.0 + wave * 6.0), s.a);
}
