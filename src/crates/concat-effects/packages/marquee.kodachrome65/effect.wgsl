struct Params { amount: f32 }
// 柯达彩: dense, saturated, warm reds and deep shadows.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let rich = mix(vec3<f32>(l), c.rgb, 1.55) * vec3<f32>(1.1, 1.0, 0.84);
    let look = max((rich - vec3<f32>(0.48)) * 1.3 + vec3<f32>(0.46), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
