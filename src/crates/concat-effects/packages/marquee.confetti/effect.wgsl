struct Params { amount: f32 }
// 纸屑: bright paper confetti tumbling down over the picture.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var over = vec3<f32>(0.0);
    var cover = 0.0;
    for (var k = 0; k < 3; k++) {
        let layer = f32(k);
        let scale = 7.0 + layer * 4.0;
        let speed = 0.16 + 0.05 * layer;
        let q = p * scale + vec2<f32>(sin(t * 1.3 + layer * 2.0) * 0.4, -t * speed * scale);
        let id = floor(q);
        let here = hash(id, 11.0 + layer);
        if (here < 0.45) { continue; }
        var f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 12.0 + layer), hash(id, 13.0 + layer)) - vec2<f32>(0.5)) * 0.5;
        let spin = t * (2.0 + 4.0 * here) + here * 30.0;
        f = vec2<f32>(f.x * cos(spin) - f.y * sin(spin), f.x * sin(spin) + f.y * cos(spin));
        let flip = abs(cos(t * 3.0 + here * 20.0));
        let piece = step(abs(f.x), 0.13) * step(abs(f.y), 0.06 * flip + 0.015);
        let pick = hash(id, 14.0 + layer);
        let col = select(select(select(vec3<f32>(1.0, 0.3, 0.45), vec3<f32>(1.0, 0.85, 0.2), pick > 0.25), vec3<f32>(0.25, 0.8, 1.0), pick > 0.5), vec3<f32>(0.45, 1.0, 0.5), pick > 0.75);
        over = mix(over, col * (0.75 + 0.25 * flip), piece);
        cover = max(cover, piece);
    }
    let look = mix(c.rgb, over, cover);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
