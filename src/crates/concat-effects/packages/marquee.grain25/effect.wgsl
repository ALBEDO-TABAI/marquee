struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let a = params.amount / 100.0;
    let c = sample(uv);
    let n = hash(floor(uv * frame.size), fract(frame.time * 7.31)) - 0.5;
    let rgb = c.rgb + vec3<f32>(n * a * 0.22);
    return vec4<f32>(rgb, c.a);
}
