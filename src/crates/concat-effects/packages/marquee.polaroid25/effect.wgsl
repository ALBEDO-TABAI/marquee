struct Params { amount: f32 }
// 拍立得: milky blacks, cyan shadows, cream highlights, soft corners.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let soft = mix(vec3<f32>(l), c.rgb, 0.72);
    let toned = soft + mix(vec3<f32>(-0.06, 0.03, 0.08), vec3<f32>(0.08, 0.05, -0.08), smoothstep(0.2, 0.8, l));
    let look = vignette(matte(toned, 0.13, 0.9), uv, 0.35);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
