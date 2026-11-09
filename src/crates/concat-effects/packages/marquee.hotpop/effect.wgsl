struct Params { amount: f32 }
// 热门弹出: the picture pops - a springy punch-in, colour up, a flash and burst lines.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(1.2);
    let spring = exp(-ph * 7.0) * cos(ph * 22.0);
    let zoom = 1.0 + 0.09 * spring * a;
    let q = (uv - vec2<f32>(0.5)) / zoom + vec2<f32>(0.5);
    let s = sample(q);
    let flash = exp(-ph * 14.0) * 0.5;
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    let ang = atan2(d.y, d.x);
    let burst = step(0.82, fract(ang * 3.8197 + 0.5)) * smoothstep(0.25, 0.6, length(d)) * exp(-ph * 5.0);
    let look = saturation(s.rgb, 1.45) * 1.05 + vec3<f32>(flash) + vec3<f32>(1.0, 0.85, 0.3) * burst;
    return vec4<f32>(mix(c.rgb, look, a), s.a);
}
