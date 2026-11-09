struct Params { amount: f32 }
// 滚动: the picture rolling up the screen like a lost vertical hold.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let y = fract(uv.y + t * 0.5 * a);
    let s = sample(vec2<f32>(uv.x, y));
    let seam = 1.0 - smoothstep(0.0, 0.03, min(y, 1.0 - y));
    return vec4<f32>(s.rgb * (1.0 - seam * 0.85), s.a);
}
