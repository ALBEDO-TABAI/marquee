struct Params { amount: f32 }
// 漂白: washed high key, the colour nearly gone.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = luma(c.rgb);
    let look = mix(vec3<f32>(l), c.rgb, 0.35) * 0.82 + vec3<f32>(0.2);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
