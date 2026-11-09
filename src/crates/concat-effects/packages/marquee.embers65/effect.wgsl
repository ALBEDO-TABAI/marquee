struct Params { amount: f32 }
// 火星: glowing sparks rising and flickering out, the bottom warmed.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var sparks = vec3<f32>(0.0);
    for (var k = 0; k < 3; k++) {
        let layer = f32(k);
        let scale = 5.0 + layer * 4.0;
        let speed = 0.18 + 0.08 * layer;
        let q = p * scale + vec2<f32>(sin(p.y * 6.0 + t * 1.5 + layer) * 0.35, t * speed * scale);
        let id = floor(q);
        if (hash(id, 31.0 + layer) < 0.5) { continue; }
        let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 32.0 + layer), hash(id, 33.0 + layer)) - vec2<f32>(0.5)) * 0.6;
        let flick = 0.4 + 0.6 * step(0.3, hash(id + vec2<f32>(floor(t * 10.0), 0.0), 34.0));
        let e = (exp(-(f.x * f.x * 500.0 + f.y * f.y * 90.0)) + exp(-dot(f, f) * 40.0) * 0.25) * flick;
        sparks += mix(vec3<f32>(1.0, 0.35, 0.05), vec3<f32>(1.0, 0.85, 0.4), hash(id, 35.0)) * e * 2.2;
    }
    let heat = vec3<f32>(1.0, 0.45, 0.1) * smoothstep(0.4, 1.0, uv.y) * 0.35;
    let look = screen(c.rgb, min(sparks + heat, vec3<f32>(1.5)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
