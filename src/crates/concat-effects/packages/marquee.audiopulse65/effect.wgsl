struct Params { amount: f32 }
// 节奏脉冲: the picture punches and flashes on every beat.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let beat = pow(1.0 - fract(t * 2.0), 4.0);
    let zoom = 1.0 + 0.07 * beat * a;
    let q = (uv - vec2<f32>(0.5)) / zoom + vec2<f32>(0.5);
    let s = sample(q);
    let d = length((uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0));
    let ring = exp(-abs(d - (1.0 - beat) * 0.9) * 30.0) * beat;
    let look = s.rgb * (1.0 + 0.18 * beat) + vec3<f32>(1.0, 0.5, 0.9) * ring * 0.6;
    return vec4<f32>(mix(c.rgb, look, a), s.a);
}
