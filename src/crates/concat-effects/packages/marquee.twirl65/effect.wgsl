struct Params { amount: f32 }
// 扭转: the whole picture wrung back and forth about its middle.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    let r = length(d);
    let ang = sin(t * 2.0) * 1.2 * a * smoothstep(0.9, 0.0, r);
    let rd = vec2<f32>(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
    let s = sample(vec2<f32>(0.5) + rd / vec2<f32>(aspect, 1.0) / (1.0 + 0.08 * a));
    return s;
}
