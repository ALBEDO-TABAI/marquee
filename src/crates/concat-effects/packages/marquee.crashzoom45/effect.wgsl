struct Params { amount: f32 }
// 急推: a sudden punch-in on the middle, smeared with zoom blur.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(1.5);
    let push = smoothstep(0.0, 0.18, ph) * (1.0 - smoothstep(0.75, 1.0, ph));
    let speed = smoothstep(0.0, 0.09, ph) * (1.0 - smoothstep(0.09, 0.2, ph));
    let zoom = 1.0 + 0.45 * push * a;
    let mid = vec2<f32>(0.5);
    var sum = vec4<f32>(0.0);
    for (var i = 0; i < 16; i++) {
        let z = zoom * (1.0 + speed * a * 0.25 * f32(i) / 15.0);
        sum += sample(mid + (uv - mid) / z);
    }
    return sum / 16.0;
}
