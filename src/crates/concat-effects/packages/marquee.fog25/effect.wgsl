struct Params { amount: f32 }
// 薄雾: a soft fog rolling slowly across, thickest at the ground.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let n = fbm(p * 2.2 + vec2<f32>(t * 0.12, 0.0), 50.0) * 0.7 + fbm(p * 4.5 - vec2<f32>(t * 0.2, 0.0), 51.0) * 0.3;
    let depth = mix(0.35, 0.9, smoothstep(0.1, 1.0, uv.y));
    let thick = clamp(n * depth * 1.25, 0.0, 0.9);
    let mist = vec3<f32>(0.86, 0.89, 0.92);
    let look = mix(c.rgb * 0.9 + vec3<f32>(0.05), mist, thick);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
