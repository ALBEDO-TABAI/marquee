struct Params { amount: f32 }
// 雨丝: rain streaking down, the picture cooled and darkened.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var streaks = 0.0;
    for (var k = 0; k < 3; k++) {
        let layer = f32(k);
        let scale = vec2<f32>(40.0 + layer * 25.0, 3.0 + layer);
        let slant = p.x + p.y * 0.15;
        let q = vec2<f32>(slant, p.y) * scale + vec2<f32>(0.0, -t * (4.0 + layer * 1.5) * scale.y);
        let id = floor(q);
        if (hash(id, 130.0 + layer) < 0.75) { continue; }
        let f = fract(q);
        let x = abs(f.x - 0.5 - (hash(id, 131.0 + layer) - 0.5) * 0.5);
        let len = 0.3 + 0.4 * hash(id, 132.0 + layer);
        let y0 = hash(id, 133.0 + layer) * (1.0 - len);
        let along = step(y0, f.y) * step(f.y, y0 + len) * smoothstep(y0, y0 + len, f.y);
        streaks += (1.0 - smoothstep(0.03, 0.12, x)) * along * (0.5 + 0.25 * layer);
    }
    let wet = c.rgb * vec3<f32>(0.72, 0.8, 0.92);
    let look = wet + vec3<f32>(0.75, 0.85, 1.0) * min(streaks, 1.0) * 0.8;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
