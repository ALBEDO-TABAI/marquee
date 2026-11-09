struct Params { amount: f32 }
// 漫画网: flat comic colours, ink outlines and halftone shadows.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let flat = floor(clamp(c.rgb, vec3<f32>(0.0), vec3<f32>(1.0)) * 3.0 + vec3<f32>(0.5)) / 3.0;
    let vivid = saturation(flat, 1.35);
    let ink = smoothstep(0.18, 0.45, edge_at(uv));
    let cell = max(frame.size.y / 70.0, 3.0);
    let rot = vec2<f32>(uv.x + uv.y, uv.y - uv.x) * frame.size / (cell * 1.414);
    let f = fract(rot) - vec2<f32>(0.5);
    let shade = 1.0 - clamp(luma(c.rgb) * 1.4, 0.0, 1.0);
    let dot = 1.0 - smoothstep(shade * 0.55 - 0.05, shade * 0.55 + 0.05, length(f));
    let look = vivid * (1.0 - dot * 0.55) * (1.0 - ink);
    let over = max(c.rgb - vec3<f32>(1.0), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look + over, a), c.a);
}
