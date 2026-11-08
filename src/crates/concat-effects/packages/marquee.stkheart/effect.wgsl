struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let p = uv * 2.0 - vec2<f32>(1.0);
    let d = length(p);
    let shape = 1.0 - smoothstep(0.35, 0.55, d);
    let col = vec3<f32>(0.004, 0.725, 0.776);
    let over = mix(c.rgb, col, shape * 0.85);
    return vec4<f32>(mix(c.rgb, over, a), max(c.a, shape * a));
}
