struct Params { amount: f32 }
// 漂白旁路: low saturation, hard contrast.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    // Silver kept: the mono laid over the colour, half the saturation, hard.
    let l = luma(c.rgb);
    let laid = mix(c.rgb, vec3<f32>(l), 0.55);
    let look = clamp((laid - vec3<f32>(0.5)) * 1.35 + vec3<f32>(0.5), vec3<f32>(0.0), vec3<f32>(1.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
