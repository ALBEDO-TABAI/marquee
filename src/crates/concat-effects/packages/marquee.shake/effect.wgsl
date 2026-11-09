struct Params { amount: f32 }
// 抖动: a hard, jittering camera shake.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let tick = floor(t * 24.0);
    let j = vec2<f32>(hash(vec2<f32>(tick, 0.0), 210.0), hash(vec2<f32>(tick, 1.0), 211.0)) - vec2<f32>(0.5);
    let zoom = 1.0 + 0.06 * a;
    let q = (uv - vec2<f32>(0.5)) / zoom + vec2<f32>(0.5) + j * 0.045 * a;
    return sample(q);
}
