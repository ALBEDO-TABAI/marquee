struct Params { amount: f32 }
// 浮雕: the picture pressed into grey metal, lit from the top left.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let o = vec2<f32>(1.5) / frame.size;
    let hi = luma(sample(uv - o).rgb);
    let lo = luma(sample(uv + o).rgb);
    let relief = 0.5 + (hi - lo) * 3.0;
    let look = vec3<f32>(relief) * vec3<f32>(1.0, 0.98, 0.95) + (c.rgb - vec3<f32>(luma(c.rgb))) * 0.15;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
