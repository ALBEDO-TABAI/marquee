struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let a = params.amount / 100.0;
    let c = sample(uv);
    let line = step(0.5, fract(uv.y * frame.size.y * 0.5));
    let rgb = c.rgb * (1.0 - line * a * 0.45);
    return vec4<f32>(rgb, c.a);
}
