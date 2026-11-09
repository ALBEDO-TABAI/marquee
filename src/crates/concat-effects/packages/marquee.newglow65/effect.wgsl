struct Params { amount: f32 }
// 新潮辉光: highlights bloom into a soft pink-white glow.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let r = frame.size.y / 14.0;
    let blurred = soften(uv, r);
    let bloom = max(blurred - vec3<f32>(0.58), vec3<f32>(0.0)) * 1.7 * vec3<f32>(1.0, 0.8, 0.95);
    let look = screen(c.rgb * vec3<f32>(1.02, 0.97, 1.0), max(bloom, vec3<f32>(0.0)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
