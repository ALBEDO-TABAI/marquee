struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let e = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    let bar = 1.0 - smoothstep(0.04, 0.11, e);
    let framed = mix(c.rgb * 0.92, vec3<f32>(0.05, 0.04, 0.03), bar * 0.65);
    return vec4<f32>(mix(c.rgb, framed, a), c.a);
}
