struct Params { amount: f32 }
// 拍立得: milky blacks, cyan shadows, cream highlights.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = luma(c.rgb);
    let soft = mix(vec3<f32>(l), c.rgb, 0.8);
    let toned = soft + mix(vec3<f32>(-0.03, 0.02, 0.05), vec3<f32>(0.05, 0.03, -0.04), smoothstep(0.2, 0.8, l));
    let look = matte(toned, 0.08, 0.92);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
