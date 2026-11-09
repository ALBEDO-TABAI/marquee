struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let order = reveal_order(uv);
    let rank = order;
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let ct = frame.clip_time;
    // A halo that swells and settles round the glyphs, the glyphs themselves
    // untouched. Zero at the start of the loop. (Was a copy of 闪烁.)
    let swell = (0.5 - 0.5 * cos(ct * mix(2.2, 6.0, amt))) * (0.7 + 0.3 * sin(rank * 6.0 + ct));
    let c = sample(uv);
    let r = mix(0.006, 0.018, amt);
    var halo = 0.0;
    for (var i = 0; i < 8; i = i + 1) {
        let a = f32(i) * 0.785398163;
        halo = max(halo, sample(uv + vec2<f32>(cos(a), sin(a)) * r).a);
    }
    let ring = halo * swell * 0.55 * (1.0 - c.a);
    let glow = vec3<f32>(1.0, 0.96, 0.86);
    let a = c.a + ring;
    let rgb = select(c.rgb, (c.rgb * c.a + glow * ring) / max(a, 1e-4), a > 0.0);
    return vec4<f32>(rgb, a);
}
