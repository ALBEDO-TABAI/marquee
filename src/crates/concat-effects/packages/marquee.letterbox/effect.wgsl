struct Params { amount: f32 }
// 宽银幕: black bars to 2.39:1.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    // Bars to 2.39:1 on whatever frame this is.
    let h = max(0.0, (1.0 - aspect / 2.39) * 0.5);
    let px = 1.0 / max(frame.size.y, 1.0);
    let bar = 1.0 - smoothstep(h - px, h + px, min(uv.y, 1.0 - uv.y));
    let look = mix(c.rgb, vec3<f32>(0.0), bar);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
