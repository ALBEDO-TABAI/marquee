struct Params { amount: f32 }
// 新潮辉光: highlights bloom into a soft pink-white glow.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let blurred = soften(uv, 14.0);
    let bloom = max(blurred - vec3<f32>(0.55), vec3<f32>(0.0)) * 2.2 * vec3<f32>(1.0, 0.86, 0.95);
    let look = screen(c.rgb, clamp(bloom, vec3<f32>(0.0), vec3<f32>(1.0)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
