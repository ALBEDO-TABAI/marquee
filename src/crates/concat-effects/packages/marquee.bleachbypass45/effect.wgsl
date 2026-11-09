struct Params { amount: f32 }
// 漂白旁路: the silver kept - low saturation, hard contrast.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let laid = mix(c.rgb, vec3<f32>(l), 0.6);
    let look = max((laid - vec3<f32>(0.5)) * 1.55 + vec3<f32>(0.5), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
