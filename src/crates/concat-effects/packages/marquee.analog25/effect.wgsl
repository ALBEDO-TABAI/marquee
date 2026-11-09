struct Params { amount: f32 }
// 胶片模拟: a warm, lifted print with grain.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    // A print: toe and shoulder rolled, blacks lifted, warm, a fine grain.
    let curved = film_curve(c.rgb, 0.35, 0.3) * vec3<f32>(1.05, 1.0, 0.9);
    let look = matte(curved, 0.06, 0.95) + grain_at(uv, 0.06);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
