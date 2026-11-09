struct Params { amount: f32 }
// 水下: a ripple and the colour of water.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    // A slow ripple, red absorbed, a blue-green cast.
    let wave = vec2<f32>(sin(uv.y * 28.0 + frame.time * 1.7) * 0.004, 0.0);
    let w = sample(uv + wave);
    let look = w.rgb * vec3<f32>(0.55, 0.95, 1.08) + vec3<f32>(0.0, 0.03, 0.07);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
