struct Params { amount: f32 }

// 打字光标入场: typed on glyph by glyph, a blinking highlight cursor at the newest one.
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
    let c = sample(uv);
    let typed = select(0.0, 1.0, rank <= progress);
    let blink = step(0.5, fract(ct * 2.5));
    let newest = (1.0 - smoothstep(0.15, 0.35, progress - rank)) * typed * select(blink, 1.0, progress < 1.0);
    let cursor = vec3<f32>(1.0, 0.8, 0.2);
    return vec4<f32>(mix(c.rgb, cursor, newest * 0.85), c.a * typed);
}
