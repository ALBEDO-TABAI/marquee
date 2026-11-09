struct Params { amount: f32 }
// X光: the negative in a cold blue mono.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = 1.0 - luma(clamp(c.rgb, vec3<f32>(0.0), vec3<f32>(1.0)));
    let look = vec3<f32>(smoothstep(0.1, 0.95, l)) * vec3<f32>(0.78, 0.92, 1.0);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
