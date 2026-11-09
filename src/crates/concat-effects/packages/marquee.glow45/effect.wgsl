struct Params { amount: f32 }
// 辉光: the whole picture glowing softly, dreamlike.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let wide = soften(uv, frame.size.y / 9.0);
    let mid = soften(uv, frame.size.y / 24.0);
    let glow = (wide * 0.6 + mid * 0.4);
    let look = screen(contrast(c.rgb, 1.08), glow * 0.75);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
