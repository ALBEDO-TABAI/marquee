struct Params { amount: f32 }

// 摆动入场: the title swings down from its top edge like a hanging sign, and settles.
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
    let ang = 0.9 * (1.0 - local) * cos(local * 3.1416 * 2.5);
    let pivot = vec2<f32>(0.5, 0.3);
    let d = uv - pivot;
    let r = vec2<f32>(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
    let c = sample(pivot + r);
    return vec4<f32>(c.rgb, c.a * min(local * 2.5, 1.0));
}
