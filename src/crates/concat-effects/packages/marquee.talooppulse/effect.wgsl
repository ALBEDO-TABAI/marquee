struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let order = reveal_order(uv);
    let rank = order;
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let window = mix(0.20, 1.20, 1.0 - amt);
    let dur = max(frame.clip_duration, window + 0.05);
    let ct = frame.clip_time;
    // A cosine, so the title opens whole; the glyphs fall out of step over
    // the first 0.6 s rather than starting out of it.
    let stagger = rank * 12.0 * smoothstep(0.0, 0.6, ct);
    let progress = 0.5 + 0.5 * cos(ct * mix(2.2, 7.5, amt) + stagger);
    let local = 0.62 + 0.38 * progress;

    var suv = uv;

    let c = sample(suv);
    var rgb = c.rgb;
    rgb = rgb * (0.72 + 0.28 * (0.5 + 0.5 * cos(ct * mix(3.0, 8.0, amt) + stagger * 0.5)));
    return vec4<f32>(rgb, c.a * local);
}
