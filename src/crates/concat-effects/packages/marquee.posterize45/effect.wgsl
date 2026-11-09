struct Params { amount: f32 }
// 色调分离: five levels a channel.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let steps = 4.0;
    let look = floor(clamp(c.rgb, vec3<f32>(0.0), vec3<f32>(1.0)) * steps + vec3<f32>(0.5)) / steps;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
