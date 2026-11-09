struct Params { amount: f32 }
// 漂白: washed high key, the colour nearly gone.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let look = mix(vec3<f32>(l), c.rgb, 0.3) * 0.75 + vec3<f32>(0.26);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
