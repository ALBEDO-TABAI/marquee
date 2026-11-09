struct Params { amount: f32 }
// 双色调: brightness mapped from indigo shadows to amber highlights.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let level = luma(c.rgb);
    let l = smoothstep(0.0, 1.0, level);
    // Light past white is carried on above the highlight colour.
    let look = mix(vec3<f32>(0.12, 0.1, 0.38), vec3<f32>(1.0, 0.78, 0.45), l) + vec3<f32>(max(level - 1.0, 0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
