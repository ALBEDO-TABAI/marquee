struct Params { amount: f32 }
// 运动模糊: the picture smeared sideways as if moving fast.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let len = 0.06 * a;
    var sum = vec4<f32>(0.0);
    for (var i = 0; i < 20; i++) {
        sum += sample(uv + vec2<f32>((f32(i) / 19.0 - 0.5) * len, 0.0));
    }
    return sum / 20.0;
}
