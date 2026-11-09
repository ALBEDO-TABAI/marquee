struct Params { amount: f32 }
// 过饱和: colour pushed to twice as rich.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let look = max(mix(vec3<f32>(luma(c.rgb)), c.rgb, 2.1), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
