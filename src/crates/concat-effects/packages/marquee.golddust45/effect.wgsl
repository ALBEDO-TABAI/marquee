struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let h = hash(uv * 48.0 + vec2<f32>(2.1, 7.3), 2.1);
    let speck = smoothstep(0.72, 0.92, h);
    let tint = vec3<f32>(0.95, 0.9, 0.75);
    let over = mix(c.rgb, tint, speck * 0.55);
    return vec4<f32>(mix(c.rgb, clamp(over, vec3<f32>(0.0), vec3<f32>(1.0)), a), c.a);
}
