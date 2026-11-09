struct Params { amount: f32 }
// 电影宽屏: 2:1 bars over a teal-orange grade.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    // 2:1 bars and a teal-orange grade between them.
    let h = max(0.0, (1.0 - aspect / 2.0) * 0.5);
    let px = 1.0 / max(frame.size.y, 1.0);
    let bar = 1.0 - smoothstep(h - px, h + px, min(uv.y, 1.0 - uv.y));
    let l = luma(c.rgb);
    let graded = c.rgb + mix(vec3<f32>(-0.04, 0.02, 0.06), vec3<f32>(0.07, 0.02, -0.05), smoothstep(0.2, 0.8, l));
    let look = mix(graded, vec3<f32>(0.0), bar);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
