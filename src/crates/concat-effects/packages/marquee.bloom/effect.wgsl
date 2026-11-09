struct Params { amount: f32 }
// 溢光: the highlights spill over into a bright warm haze.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let r = frame.size.y / 10.0;
    let near = halation(uv, vec3<f32>(0.0), 0.7, r * 0.4, vec3<f32>(1.0, 0.92, 0.82), 0.7);
    let far = halation(uv, vec3<f32>(0.0), 0.65, r, vec3<f32>(1.0, 0.85, 0.7), 0.6);
    let look = screen(c.rgb * 0.96, max(near + far, vec3<f32>(0.0)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
