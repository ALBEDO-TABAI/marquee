struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let a = params.amount / 100.0;
    let c = sample(uv);
    let cell = floor(uv * vec2<f32>(48.0, 27.0));
    let n = hash(cell, fract(frame.time * 3.17)) - 0.5;
    let rgb = c.rgb + vec3<f32>(n * a * 0.28);
    return vec4<f32>(rgb, c.a);
}
