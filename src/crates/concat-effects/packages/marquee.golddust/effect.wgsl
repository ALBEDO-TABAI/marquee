struct Params { amount: f32 }
// 金粉扬: gold dust lifting and swirling up through the picture.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var dust = 0.0;
    for (var k = 0; k < 3; k++) {
        let layer = f32(k);
        let scale = 10.0 + layer * 8.0;
        let q = p * scale + vec2<f32>(sin(p.y * 4.0 + t + layer) * 0.5 - t * 0.1 * scale * 0.2, t * (0.1 + 0.04 * layer) * scale);
        let id = floor(q);
        if (hash(id, 260.0 + layer) < 0.6) { continue; }
        let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 261.0 + layer), hash(id, 262.0 + layer)) - vec2<f32>(0.5)) * 0.6;
        let tw = 0.5 + 0.5 * sin(t * 6.0 + hash(id, 263.0) * 6.28);
        dust += (exp(-dot(f, f) * 90.0) + exp(-dot(f, f) * 15.0) * 0.2) * (0.4 + 0.6 * tw);
    }
    let warm = c.rgb * vec3<f32>(1.05, 0.99, 0.92);
    let look = screen(warm, vec3<f32>(1.0, 0.78, 0.3) * min(dust * 1.4, 1.3));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
