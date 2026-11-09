struct Params { amount: f32 }
// 暗角: the corners and edges sink into shadow.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = length((uv - vec2<f32>(0.5)) * vec2<f32>(1.0, 1.0 / max(aspect, 0.5)) * 1.6);
    let fall = smoothstep(0.35, 1.05, d);
    let look = c.rgb * (1.0 - fall * 0.9);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
