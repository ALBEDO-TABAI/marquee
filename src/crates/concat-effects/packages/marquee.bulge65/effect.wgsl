struct Params { amount: f32 }
// 鼓包: the middle of the picture swelling outwards like a lens bubble.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let mid = vec2<f32>(0.5);
    let d = (uv - mid) * vec2<f32>(aspect, 1.0);
    let r = length(d);
    let radius = 0.5;
    let k = (0.55 + 0.05 * sin(t * 2.0)) * a;
    let f = select(1.0, mix(1.0, pow(r / radius, k), 1.0), r < radius);
    let q = mid + d * f / vec2<f32>(aspect, 1.0);
    let s = sample(q);
    return vec4<f32>(s.rgb, s.a);
}
