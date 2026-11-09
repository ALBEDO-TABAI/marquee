struct Params { amount: f32 }
// 变焦模糊: the picture streaked out from the middle, a zoom burst.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let k = 0.14 * a;
    let mid = vec2<f32>(0.5);
    var sum = vec4<f32>(0.0);
    for (var i = 0; i < 20; i++) {
        sum += sample(mid + (uv - mid) * (1.0 - k * f32(i) / 19.0));
    }
    return sum / 20.0;
}
