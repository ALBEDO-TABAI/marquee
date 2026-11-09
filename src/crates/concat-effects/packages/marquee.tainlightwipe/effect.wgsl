struct Params { amount: f32 }

// 光线划过入场: a band of light sweeps across, the title appearing behind it.
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
    let front = progress * 1.3 - 0.15;
    let show = 1.0 - smoothstep(front - 0.01, front + 0.01, uv.x);
    let beam = exp(-abs(uv.x - front) * 28.0) * (1.0 - smoothstep(0.85, 1.0, progress));
    let c = sample(uv);
    return vec4<f32>(c.rgb + vec3<f32>(1.0, 0.95, 0.8) * beam * 1.2, c.a * max(show, beam * 0.6 * c.a));
}
