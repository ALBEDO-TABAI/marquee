struct Params { amount: f32 }

// 开幕入场: the title revealed from the middle out, like curtains parting.
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
    let open = progress * 0.56;
    let show = 1.0 - smoothstep(open - 0.02, open + 0.02, abs(uv.x - 0.5));
    let c = sample(uv);
    return vec4<f32>(c.rgb, c.a * show);
}
