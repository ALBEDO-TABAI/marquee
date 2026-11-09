struct Params { amount: f32 }

// 旋弹入场: the title spins in from a quarter turn, growing as it turns.
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
    let ang = (1.0 - local) * 1.7;
    let s = 0.35 + 0.65 * local;
    let d = (uv - vec2<f32>(0.5)) / s;
    let r = vec2<f32>(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
    let c = sample(vec2<f32>(0.5) + r);
    return vec4<f32>(c.rgb, c.a * local);
}
