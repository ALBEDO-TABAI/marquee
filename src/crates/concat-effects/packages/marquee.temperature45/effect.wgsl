struct Params { amount: f32 }
// 色温: warmer, red up and blue down.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let look = c.rgb * vec3<f32>(1.12, 1.0, 0.82);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
