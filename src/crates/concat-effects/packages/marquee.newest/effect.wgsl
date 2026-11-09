struct Params { amount: f32 }
// 新潮颗粒: crushed contrast and a heavy, coarse grain.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let cell = floor(uv * frame.size / 2.0);
    let coarse = hash(cell, fract(t * 7.31)) - 0.5;
    let punchy = max((c.rgb - vec3<f32>(0.5)) * 1.3 + vec3<f32>(0.5), vec3<f32>(0.0));
    let look = saturation(punchy, 0.85) + vec3<f32>(coarse * 0.28);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
