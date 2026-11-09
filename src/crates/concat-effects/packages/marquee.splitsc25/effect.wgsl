struct Params { amount: f32 }
// 左右分屏: the picture twice, side by side, split by a white line.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let half = step(0.5, uv.x);
    let lx = fract(uv.x * 2.0) * 0.5 + 0.25;
    let s = sample(vec2<f32>(lx, uv.y));
    let line = 1.0 - smoothstep(1.0, 2.0, abs(uv.x - 0.5) * frame.size.x);
    let look = mix(s.rgb * mix(1.0, 0.92, half), vec3<f32>(1.0) + max(s.rgb - vec3<f32>(1.0), vec3<f32>(0.0)), line);
    return vec4<f32>(mix(c.rgb, look, step(0.01, a)), c.a);
}
