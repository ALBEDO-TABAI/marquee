struct Params { amount: f32 }
// 像素化: chunky square pixels in a short palette, like an old game.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let n = mix(140.0, 40.0, a);
    let cell = frame.size.y / n;
    let at = floor(uv * frame.size / cell);
    let s = sample((at + vec2<f32>(0.5)) * cell / frame.size);
    let look = floor(clamp(s.rgb, vec3<f32>(0.0), vec3<f32>(1.0)) * 5.0 + vec3<f32>(0.5)) / 5.0;
    return vec4<f32>(mix(c.rgb, mix(s.rgb, look, a), min(a * 4.0, 1.0)), c.a);
}
