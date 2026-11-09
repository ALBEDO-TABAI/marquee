struct Params { amount: f32 }
// 色散: colour fringes spreading towards the edges, red out and blue in.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = uv - vec2<f32>(0.5);
    let k = 0.06 * a * (0.8 + 0.2 * sin(t * 1.5));
    let r = sample(vec2<f32>(0.5) + d * (1.0 + k)).r;
    let g = sample(vec2<f32>(0.5) + d * (1.0 + k * 0.35)).g;
    let b = sample(vec2<f32>(0.5) + d * (1.0 - k * 0.3)).b;
    return vec4<f32>(r, g, b, c.a);
}
