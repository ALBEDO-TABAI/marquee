struct Params { amount: f32 }
// 漂浮尘埃: warm dust motes drifting and glinting in the light.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var motes = 0.0;
    for (var k = 0; k < 3; k++) {
        let layer = f32(k);
        let scale = 9.0 + layer * 7.0;
        let drift = vec2<f32>(t * (0.03 + 0.01 * layer), -t * 0.02);
        let wob = vec2<f32>(value_noise(p * 2.0 + vec2<f32>(t * 0.3, layer), 20.0 + layer), value_noise(p * 2.0 + vec2<f32>(layer, t * 0.3), 30.0 + layer)) - vec2<f32>(0.5);
        let q = (p + drift + wob * 0.04) * scale;
        let id = floor(q);
        if (hash(id, 21.0 + layer) < 0.55) { continue; }
        let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 22.0 + layer), hash(id, 23.0 + layer)) - vec2<f32>(0.5)) * 0.6;
        let size = 0.08 + 0.1 * hash(id, 24.0 + layer);
        let twinkle = 0.5 + 0.5 * sin(t * (2.0 + 3.0 * hash(id, 25.0)) + hash(id, 26.0) * 6.28);
        motes += exp(-dot(f, f) / (size * size)) * (0.35 + 0.65 * twinkle) * (1.0 - layer * 0.25);
    }
    let haze = vec3<f32>(1.0, 0.85, 0.6) * 0.1;
    let look = screen(c.rgb * vec3<f32>(1.04, 1.0, 0.94) + haze, vec3<f32>(1.0, 0.88, 0.62) * min(motes * 1.6, 1.4));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
