struct Params { amount: f32 }
// 色相偏移: every hue turned, up to 150 degrees at full amount.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    // Turned, not mixed: a mix between two hues would only grey the colour.
    return vec4<f32>(hue_rotate(c.rgb, 150.0 * a), c.a);
}
