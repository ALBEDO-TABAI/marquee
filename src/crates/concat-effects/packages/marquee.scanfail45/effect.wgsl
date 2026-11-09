struct Params { amount: f32 }
// 扫描失败: a scanner line sweeping down, the rows below it smeared from where it is.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(2.5);
    let line_y = ph * 1.1;
    let below = step(line_y, uv.y);
    let smear = sample(vec2<f32>(uv.x + sin(uv.y * 80.0) * 0.004, min(line_y, 0.999)));
    let s = sample(uv);
    let shifted = vec3<f32>(smear.r * 0.9, smear.g * 1.05, smear.b * 1.15);
    let beam = exp(-abs(uv.y - line_y) * frame.size.y * 0.3) * 1.2;
    let look = mix(s.rgb, shifted, below) + vec3<f32>(0.4, 1.0, 1.0) * beam;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
