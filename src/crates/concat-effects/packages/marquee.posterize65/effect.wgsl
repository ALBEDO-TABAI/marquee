struct Params { amount: f32 }
// 色调分离: four flat levels a channel - hard banding.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    // The amount sets the bands: 12 levels at the lightest touch, 4 at full.
    let steps = mix(12.0, 3.0, a);
    let look = floor(max(c.rgb, vec3<f32>(0.0)) * steps + vec3<f32>(0.5)) / steps;
    return vec4<f32>(mix(c.rgb, look, min(a * 2.0, 1.0)), c.a);
}
