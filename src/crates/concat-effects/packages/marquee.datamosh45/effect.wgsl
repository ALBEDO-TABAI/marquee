struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let a = params.amount / 100.0;
    let band = step(0.46, fract(uv.y * 9.0 + 0.17));
    let shift = vec2<f32>(0.012 * a * (0.4 + band), 0.0);
    let r = sample(uv + shift).r;
    let g = sample(uv).g;
    let b = sample(uv - shift).b;
    let c = sample(uv);
    return vec4<f32>(mix(c.rgb, vec3<f32>(r, g, b), a), c.a);
}
