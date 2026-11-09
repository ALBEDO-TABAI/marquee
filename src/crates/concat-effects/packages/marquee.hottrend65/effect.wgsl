struct Params { amount: f32 }
// 热门光斑: soft bokeh spots of pink, gold and cyan floating over the picture.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var spots = vec3<f32>(0.0);
    for (var k = 0; k < 2; k++) {
        let layer = f32(k);
        let scale = 3.0 + layer * 2.5;
        let q = p * scale + vec2<f32>(t * 0.08 * (layer + 1.0), sin(t * 0.3 + layer) * 0.3);
        let id = floor(q);
        if (hash(id, 71.0 + layer) < 0.35) { continue; }
        let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 72.0 + layer), hash(id, 73.0 + layer)) - vec2<f32>(0.5)) * 0.4;
        let r = 0.18 + 0.14 * hash(id, 74.0 + layer);
        let disc = smoothstep(r, r * 0.8, length(f)) * (0.7 + 0.3 * sin(t * 2.0 + hash(id, 75.0) * 6.0));
        let pick = hash(id, 76.0 + layer);
        let col = select(select(vec3<f32>(1.0, 0.35, 0.65), vec3<f32>(1.0, 0.8, 0.3), pick > 0.33), vec3<f32>(0.3, 0.85, 1.0), pick > 0.66);
        spots += col * disc * 0.5;
    }
    let look = screen(c.rgb, min(spots, vec3<f32>(1.0)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
