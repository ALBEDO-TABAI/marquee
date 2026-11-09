struct Params { amount: f32 }
// 新潮颗粒: contrast and a heavy, coarse grain.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let punchy = clamp((c.rgb - vec3<f32>(0.5)) * 1.2 + vec3<f32>(0.5), vec3<f32>(0.0), vec3<f32>(1.0));
    let look = punchy + grain_at(uv, 0.2);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
