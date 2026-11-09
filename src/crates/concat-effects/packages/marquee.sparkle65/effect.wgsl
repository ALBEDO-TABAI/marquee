struct Params { amount: f32 }
// A four-pointed glint at `d` from its centre, `r` across: a hot core and
// two thin crossed rays.
fn glint(d: vec2<f32>, r: f32) -> f32 {
    let q = abs(d) / max(r, 1e-4);
    let rays = max(1.0 - q.x * 0.9 - q.y * 18.0, 0.0) + max(1.0 - q.y * 0.9 - q.x * 18.0, 0.0);
    let core = exp(-dot(q, q) * 40.0);
    return min(rays * rays + core, 1.5);
}
// 闪光粒子: white four-pointed sparkles twinkling across the picture.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var sp = 0.0;
    for (var k = 0; k < 2; k++) {
        let layer = f32(k);
        let scale = 5.0 + layer * 4.0;
        let q = p * scale;
        let id = floor(q);
        if (hash(id, 270.0 + layer) < 0.35) { continue; }
        let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 271.0 + layer), hash(id, 272.0 + layer)) - vec2<f32>(0.5)) * 0.5;
        let tw = pow(max(sin(t * (2.0 + 2.0 * hash(id, 273.0)) + hash(id, 274.0) * 6.28), 0.0), 3.0);
        sp += glint(f, 0.75 * tw) * tw * 1.4;
    }
    let look = screen(c.rgb, vec3<f32>(1.0, 0.97, 0.9) * min(sp, 1.4));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
