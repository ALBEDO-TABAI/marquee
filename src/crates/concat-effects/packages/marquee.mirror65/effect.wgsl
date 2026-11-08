struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let a = params.amount / 100.0;
    let mx = select(uv.x, 1.0 - uv.x, uv.x > 0.5);
    let c0 = sample(uv);
    let c1 = sample(vec2<f32>(mx, uv.y));
    return mix(c0, c1, a);
}
