struct Params { amount: f32 }
// 分离调色: teal shadows, orange highlights.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = luma(c.rgb);
    let look = c.rgb + mix(vec3<f32>(-0.05, 0.03, 0.09), vec3<f32>(0.09, 0.03, -0.07), smoothstep(0.15, 0.85, l));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
