struct Params { amount: f32 }
// 霓虹城: magenta shadows, cyan highlights, saturated.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let l = luma(c.rgb);
    let tone = mix(vec3<f32>(0.55, 0.08, 0.75), vec3<f32>(0.12, 0.92, 1.0), smoothstep(0.15, 0.85, l));
    let vivid = mix(vec3<f32>(l), c.rgb, 1.4);
    let look = clamp(vivid * 0.55 + tone * (0.25 + 0.6 * l), vec3<f32>(0.0), vec3<f32>(1.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
