struct Params { amount: f32 }
// 旋转模糊: the picture smeared round in a spin about the middle.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let mid = vec2<f32>(0.5);
    let d = (uv - mid) * vec2<f32>(aspect, 1.0);
    let sweep = 0.16 * a;
    var sum = vec3<f32>(0.0);
    for (var i = 0; i < 24; i++) {
        let ang = (f32(i) / 23.0 - 0.5) * sweep;
        let rd = vec2<f32>(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
        sum += sample(mid + rd / vec2<f32>(aspect, 1.0)).rgb;
    }
    return vec4<f32>(sum / 24.0, c.a);
}
