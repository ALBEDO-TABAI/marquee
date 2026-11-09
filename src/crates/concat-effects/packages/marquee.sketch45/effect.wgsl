struct Params { amount: f32 }
// 素描: a pencil drawing on white paper.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let l = luma(c.rgb);
    let b = luma(soften(uv, max(frame.size.y / 60.0, 2.0)));
    // A colour dodge of the picture over its own blur: the edges come out as lines.
    let lines = clamp(l / max(b, 0.02), 0.0, 1.0);
    let graphite = pow(lines, 4.0) * mix(0.75, 1.0, smoothstep(0.1, 0.6, l));
    let px = uv * frame.size;
    let tooth = (hash(floor(px / 2.0), 140.0) - 0.5) * 0.06;
    let hatch = step(fract((px.x + px.y) / 5.0), 0.25) * (1.0 - smoothstep(0.15, 0.45, l)) * 0.25;
    let look = vec3<f32>(clamp(graphite - hatch + tooth, 0.0, 1.0)) * vec3<f32>(0.98, 0.97, 0.94);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
