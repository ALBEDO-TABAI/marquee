struct Params { amount: f32 }
// 金肤: a golden glow on the skin, the rest warmed a little.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let skin = skin_mask(c.rgb);
    let gold = c.rgb * vec3<f32>(1.2, 1.04, 0.74) + vec3<f32>(0.03, 0.015, 0.0);
    let look = max(mix(c.rgb * vec3<f32>(1.06, 1.0, 0.9), gold, 0.45 + 0.55 * skin), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
