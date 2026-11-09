struct Params { amount: f32 }
// 色调分离: three flat, rich levels a channel - poster-hard banding.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    // The amount sets the bands: 12 levels at the lightest touch, 3 at full.
    let steps = mix(11.0, 2.0, a);
    let rich = max(saturation(c.rgb, 1.3), vec3<f32>(0.0));
    let look = floor(rich * steps + vec3<f32>(0.5)) / steps;
    return vec4<f32>(mix(c.rgb, look, min(a * 2.0, 1.0)), c.a);
}
