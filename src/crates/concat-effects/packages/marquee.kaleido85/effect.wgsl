struct Params { amount: f32 }
// 万花筒: the picture folded into a turning six-fold kaleidoscope.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    var ang = atan2(d.y, d.x) + t * 0.25;
    let r = length(d);
    let seg = 6.2832 / 6.0;
    ang = abs(ang - seg * floor(ang / seg) - seg * 0.5);
    let q = vec2<f32>(0.5) + vec2<f32>(cos(ang), sin(ang)) * r / vec2<f32>(aspect, 1.0) * 0.9;
    let k = sample(clamp(q, vec2<f32>(0.0), vec2<f32>(1.0)));
    return vec4<f32>(mix(c.rgb, k.rgb, a), c.a);
}
