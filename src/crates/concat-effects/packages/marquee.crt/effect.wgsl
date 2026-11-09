struct Params { amount: f32 }
// 显像管: an old tube screen - curved glass, scanlines, a phosphor grid.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = uv - vec2<f32>(0.5);
    let bend = d * (1.0 + dot(d, d) * 0.35 * a);
    let q = vec2<f32>(0.5) + bend;
    let inside = step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0);
    let s = sample(q).rgb;
    let line = 0.72 + 0.28 * sin(q.y * frame.size.y * 3.1416 / 1.5);
    let col = u32(floor(uv.x * frame.size.x)) % 3u;
    let mask = select(select(vec3<f32>(0.75, 0.75, 1.15), vec3<f32>(0.75, 1.15, 0.75), col == 1u), vec3<f32>(1.15, 0.75, 0.75), col == 0u);
    let flick = 0.97 + 0.03 * sin(t * 50.0);
    let look = vignette(s * line * mix(vec3<f32>(1.0), mask, 0.6) * flick * 1.15, q, 0.5) * inside;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
