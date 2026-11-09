struct Params { amount: f32 }
// 红外: false colour, greens burn to pink-white.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    // Foliage glows: green read as brightness, red and green traded.
    let glow = clamp(c.g * 1.25 + c.r * 0.2, 0.0, 1.0);
    let look = vec3<f32>(glow, c.r * 0.85, c.b * 0.9 + 0.05);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
