struct Params { amount: f32 }

// 字幕·弹出: the caption pops up from nothing with a quick overshoot.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let rank = reveal_order(uv);
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let window = mix(0.20, 1.20, 1.0 - amt);
    let dur = max(frame.clip_duration, window + 0.05);
    let ct = frame.clip_time;
    // 0 hidden, 1 at rest: an entrance from the clip's start, an exit
    // counted back from its end.
    let progress = clamp(ct / max(window * 0.75, 0.08), 0.0, 1.0);
    let local = smoothstep(rank * 0.78, rank * 0.78 + 0.22, progress);
    let s = local * (1.0 + 0.3 * sin(local * 3.1416));
    let suv = vec2<f32>(0.5) + (uv - vec2<f32>(0.5)) / max(s, 0.01);
    let c = sample(suv);
    return vec4<f32>(c.rgb, c.a * min(local * 4.0, 1.0));
}
