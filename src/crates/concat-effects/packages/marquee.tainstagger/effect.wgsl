struct Params { amount: f32 }

// 逐字显现入场: one glyph after another rises and fades in, a beat apart.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let rank = reveal_order(uv);
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let window = mix(0.20, 1.20, 1.0 - amt);
    let dur = max(frame.clip_duration, window + 0.05);
    let ct = frame.clip_time;
    // 0 hidden, 1 at rest: an entrance from the clip's start, an exit
    // counted back from its end.
    let progress = clamp(ct / window, 0.0, 1.0);
    let local = smoothstep(rank * 0.78, rank * 0.78 + 0.22, progress);
    let each = smoothstep(rank * 0.86, rank * 0.86 + 0.14, progress);
    let c = sample(uv + vec2<f32>(0.0, -(1.0 - each) * 0.05));
    return vec4<f32>(c.rgb, c.a * each);
}
