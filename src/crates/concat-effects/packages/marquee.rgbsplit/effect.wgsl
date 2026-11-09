struct Params { amount: f32 }
// RGB 分离: the red and blue pulled apart sideways, throbbing.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let pulse = 0.5 + 0.5 * sin(t * 4.0);
    let o = vec2<f32>(0.008 + 0.018 * pulse, 0.003) * a;
    let r = sample(uv + o);
    let g = sample(uv);
    let b = sample(uv - o);
    return vec4<f32>(r.r, g.g, b.b, c.a);
}
