struct Params { amount: f32 }
// 锐化: crisper edges and fine detail.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let blurred = soften(uv, max(frame.size.y / 160.0, 1.5));
    let look = max(c.rgb + (c.rgb - blurred) * 2.6, vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
