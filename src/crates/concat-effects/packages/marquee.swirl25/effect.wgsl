struct Params { amount: f32 }
// 漩涡: the middle twisted into a slowly turning whirlpool.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    let r = length(d);
    let radius = 0.55;
    let w = pow(max(1.0 - r / radius, 0.0), 2.0);
    let ang = w * (3.0 + 1.5 * sin(t * 0.8)) * a + w * t * 1.2 * a;
    let rd = vec2<f32>(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
    return sample(vec2<f32>(0.5) + rd / vec2<f32>(aspect, 1.0));
}
