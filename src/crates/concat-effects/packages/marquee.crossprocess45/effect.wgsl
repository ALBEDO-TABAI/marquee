struct Params { amount: f32 }
// 交叉冲洗: yellow-green highlights, blue shadows, hard contrast.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let x = clamp(c.rgb, vec3<f32>(0.0), vec3<f32>(1.0));
    let r = smoothstep(0.05, 0.95, x.r) * 1.05;
    let g = mix(x.g, smoothstep(0.0, 1.0, x.g), 0.6) * 1.08 + 0.02;
    let b = x.b * 0.62 + 0.2;
    let look = vec3<f32>(r, g, b) * vec3<f32>(1.0, 1.0, 0.95) + (c.rgb - x);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
