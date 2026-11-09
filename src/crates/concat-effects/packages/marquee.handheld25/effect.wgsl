struct Params { amount: f32 }
// 手持晃动: the gentle drift and sway of a handheld camera.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let s1 = value_noise(vec2<f32>(t * 0.9, 0.0), 200.0) - 0.5;
    let s2 = value_noise(vec2<f32>(t * 0.9, 7.0), 201.0) - 0.5;
    let s3 = value_noise(vec2<f32>(t * 0.6, 13.0), 202.0) - 0.5;
    let ang = s3 * 0.05 * a;
    let zoom = 1.0 + 0.07 * a;
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0) / zoom;
    let rd = vec2<f32>(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
    let q = vec2<f32>(0.5) + rd / vec2<f32>(aspect, 1.0) + vec2<f32>(s1, s2) * 0.05 * a;
    return sample(q);
}
