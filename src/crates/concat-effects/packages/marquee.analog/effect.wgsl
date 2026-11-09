struct Params { amount: f32 }
// 胶片模拟: a warm, lifted print with soft colour and grain.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let curved = film_curve(c.rgb, 0.5, 0.4) * vec3<f32>(1.1, 1.0, 0.8);
    let soft = saturation(curved, 0.82);
    let look = matte(soft, 0.1, 0.92) + grain_at(uv, 0.09);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
