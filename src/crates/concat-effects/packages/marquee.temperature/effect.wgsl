struct Params { amount: f32 }
// 色温: much warmer - red up, blue down.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let look = c.rgb * vec3<f32>(1.2, 1.03, 0.68) + vec3<f32>(0.03, 0.01, 0.0);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
