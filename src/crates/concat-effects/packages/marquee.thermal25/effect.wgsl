struct Params { amount: f32 }
// 热成像: brightness as a heat palette, blue to white.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = clamp(luma(c.rgb), 0.0, 1.0);
    var heat = mix(vec3<f32>(0.0, 0.0, 0.25), vec3<f32>(0.45, 0.0, 0.65), smoothstep(0.0, 0.3, l));
    heat = mix(heat, vec3<f32>(0.95, 0.15, 0.1), smoothstep(0.3, 0.55, l));
    heat = mix(heat, vec3<f32>(1.0, 0.85, 0.1), smoothstep(0.55, 0.8, l));
    let look = mix(heat, vec3<f32>(1.0), smoothstep(0.85, 1.0, l));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
