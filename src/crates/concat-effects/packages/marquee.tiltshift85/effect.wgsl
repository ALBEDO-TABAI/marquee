struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let o = 0.006 * a;
    let n = (sample(uv + vec2<f32>(o, 0.0)).rgb + sample(uv - vec2<f32>(o, 0.0)).rgb
           + sample(uv + vec2<f32>(0.0, o)).rgb + sample(uv - vec2<f32>(0.0, o)).rgb) * 0.25;
    let mixed = mix(c.rgb, n, 0.85);
    return vec4<f32>(mix(c.rgb, max(mixed, vec3<f32>(0.0)), a), c.a);
}
