struct Params { amount: f32 }
// 描边提取: the outlines alone, glowing in the picture's own colours on black.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let e = smoothstep(0.08, 0.5, edge_at(uv));
    let hue = saturation(c.rgb, 1.8) * 1.4 + vec3<f32>(0.15);
    let look = hue * e;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
