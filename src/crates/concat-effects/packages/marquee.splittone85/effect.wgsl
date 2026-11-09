struct Params { amount: f32 }
// 分离调色: teal shadows, orange highlights.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let look = max(c.rgb + mix(vec3<f32>(-0.1, 0.05, 0.16), vec3<f32>(0.17, 0.05, -0.14), smoothstep(0.1, 0.9, l)), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
