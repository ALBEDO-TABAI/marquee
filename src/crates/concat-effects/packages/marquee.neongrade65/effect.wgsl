struct Params { amount: f32 }
// 霓虹城: magenta shadows, cyan highlights, saturated.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let tone = mix(vec3<f32>(0.6, 0.06, 0.8), vec3<f32>(0.1, 0.95, 1.0), smoothstep(0.15, 0.85, l));
    let vivid = mix(vec3<f32>(l), c.rgb, 1.4);
    let look = max(vivid * 0.5 + tone * (0.25 + 0.65 * l), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
