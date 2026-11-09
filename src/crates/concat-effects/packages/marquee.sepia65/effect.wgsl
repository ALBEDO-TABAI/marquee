struct Params { amount: f32 }
// 褐色: the classic sepia print, brown from black to cream.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let toned = mix(vec3<f32>(0.16, 0.09, 0.04), vec3<f32>(1.0, 0.88, 0.66), smoothstep(0.0, 1.0, l));
    let look = toned + vec3<f32>(max(l - 1.0, 0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
