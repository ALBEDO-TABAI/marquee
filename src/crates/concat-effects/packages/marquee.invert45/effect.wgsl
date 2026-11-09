struct Params { amount: f32 }
// 反相: the negative.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let look = vec3<f32>(1.0) - max(c.rgb, vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
