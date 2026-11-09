struct Params { amount: f32 }
// 柔化: the whole picture softened into a smooth blur.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let r = frame.size.y / 22.0 * a;
    let look = (soften(uv, r) * 2.0 + soften(uv, r * 0.55) + soften(uv + vec2<f32>(0.5, 0.5) / frame.size, r * 0.8)) / 4.0;
    return vec4<f32>(mix(c.rgb, look, min(a * 3.0, 1.0)), c.a);
}
