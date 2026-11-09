struct Params { amount: f32 }
// 夜视: green phosphor, noise, scan lines and a dark ring.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = luma(c.rgb) * 1.6;
    let noise = grain_at(uv, 0.18).r;
    let line = 0.88 + 0.12 * step(0.5, fract(uv.y * frame.size.y * 0.5));
    let lit = (l + noise) * line;
    let look = vignette(vec3<f32>(0.2, 1.0, 0.3) * lit, uv, 0.9);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
