struct Params { amount: f32 }
// 装饰框: a cream mat and a double gold rule.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    // A cream mat with a double gold rule inside it.
    let d = min(min(uv.x * aspect, (1.0 - uv.x) * aspect), min(uv.y, 1.0 - uv.y));
    let mat = 1.0 - smoothstep(0.055, 0.06, d);
    let rule = (smoothstep(0.066, 0.068, d) - smoothstep(0.072, 0.074, d))
        + (smoothstep(0.082, 0.084, d) - smoothstep(0.086, 0.088, d));
    let gold = vec3<f32>(0.8, 0.63, 0.3);
    let look = mix(mix(c.rgb, gold, clamp(rule, 0.0, 1.0)), vec3<f32>(0.93, 0.88, 0.76), mat);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
