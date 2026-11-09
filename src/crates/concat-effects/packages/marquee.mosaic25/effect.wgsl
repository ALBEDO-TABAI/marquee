struct Params { amount: f32 }
// 马赛克: the picture laid as big bevelled tiles.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let n = mix(60.0, 16.0, a);
    let cell = frame.size.y / n;
    let at = floor(uv * frame.size / cell);
    let s = sample((at + vec2<f32>(0.5)) * cell / frame.size);
    let f = fract(uv * frame.size / cell);
    let grout = step(0.08, f.x) * step(0.08, f.y);
    let bevel = 1.0 + (0.5 - f.x) * 0.12 + (0.5 - f.y) * 0.12;
    let look = s.rgb * bevel * mix(0.55, 1.0, grout);
    return vec4<f32>(mix(c.rgb, look, min(a * 4.0, 1.0)), c.a);
}
