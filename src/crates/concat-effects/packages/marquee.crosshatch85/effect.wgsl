struct Params { amount: f32 }
// 交叉排线: a pen drawing, darker tones hatched in more directions.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let px = uv * frame.size / max(frame.size.y / 110.0, 1.5);
    let w = 0.22;
    let h1 = step(fract((px.x + px.y) / 4.0), w);
    let h2 = step(fract((px.x - px.y) / 4.0), w);
    let h3 = step(fract(px.y / 4.0), w);
    let h4 = step(fract((px.x + 0.5 * px.y) / 3.0), w);
    var ink = 0.0;
    if (l < 0.85) { ink = max(ink, h1); }
    if (l < 0.62) { ink = max(ink, h2); }
    if (l < 0.42) { ink = max(ink, h3); }
    if (l < 0.22) { ink = max(ink, h4); }
    let outline = smoothstep(0.25, 0.6, edge_at(uv));
    let paper = vec3<f32>(0.97, 0.95, 0.9);
    let look = paper * (1.0 - max(ink * 0.85, outline));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
