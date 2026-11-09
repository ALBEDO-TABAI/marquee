struct Params { amount: f32 }
// 切片故障: horizontal slices of the picture jumping sideways, colours split.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let tick = floor(t * 10.0);
    let burst = step(0.35, hash(vec2<f32>(floor(t * 3.0), 0.0), 230.0));
    let slice = floor(uv.y * (12.0 + 18.0 * hash(vec2<f32>(tick, 1.0), 231.0)));
    let h = hash(vec2<f32>(slice, tick), 232.0);
    let shift = select(0.0, (h - 0.5) * 0.18, h > 0.55) * a * (0.3 + 0.7 * burst);
    let r = sample(uv + vec2<f32>(shift + 0.012 * a * burst, 0.0)).r;
    let g = sample(uv + vec2<f32>(shift, 0.0)).g;
    let b = sample(uv + vec2<f32>(shift - 0.012 * a * burst, 0.0)).b;
    return vec4<f32>(r, g, b, c.a);
}
