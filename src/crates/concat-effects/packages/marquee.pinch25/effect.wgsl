struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let a = params.amount / 100.0;
    let d = uv - vec2<f32>(0.5);
    let r = length(d);
    let warped = uv + d * (0.8 * r * r + -0.15) * a;
    let c0 = sample(uv);
    let c1 = sample(clamp(warped, vec2<f32>(0.0), vec2<f32>(1.0)));
    return mix(c0, c1, a);
}
