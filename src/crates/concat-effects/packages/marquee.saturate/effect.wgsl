struct Params { amount: f32 }
// 过饱和: colour pushed to 1.8 times.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let look = mix(vec3<f32>(luma(c.rgb)), c.rgb, 1.8);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
