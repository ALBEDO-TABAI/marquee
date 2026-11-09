struct Params { amount: f32 }
// 柯达彩: dense, saturated, warm reds and deep shadows.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = luma(c.rgb);
    let rich = mix(vec3<f32>(l), c.rgb, 1.35) * vec3<f32>(1.06, 1.0, 0.9);
    let look = clamp((rich - vec3<f32>(0.5)) * 1.15 + vec3<f32>(0.5), vec3<f32>(0.0), vec3<f32>(1.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
