struct Params { amount: f32 }
// 桶形畸变: the picture bowed out like a wide lens, the corners pulled in.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = uv - vec2<f32>(0.5);
    let k = 0.6 * a;
    let r2 = dot(d * vec2<f32>(aspect, 1.0), d * vec2<f32>(aspect, 1.0));
    let q = vec2<f32>(0.5) + d * (1.0 + k * r2 * 0.9);
    let inside = step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0);
    let s = sample(q);
    return vec4<f32>(s.rgb * inside, c.a);
}
