struct Params { amount: f32 }

// 落幕出场: a curtain drops over the title from the top.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let rank = reveal_order(uv);
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let window = mix(0.20, 1.20, 1.0 - amt);
    let dur = max(frame.clip_duration, window + 0.05);
    let ct = frame.clip_time;
    // 0 hidden, 1 at rest: an entrance from the clip's start, an exit
    // counted back from its end.
    let progress = clamp((dur - ct) / window, 0.0, 1.0);
    let local = smoothstep(rank * 0.78, rank * 0.78 + 0.22, progress);
    let fall = 1.0 - progress;
    let edge = smoothstep(fall - 0.03, fall + 0.03, uv.y * 1.05);
    let shade = 1.0 - 0.35 * exp(-abs(uv.y * 1.05 - fall) * 30.0);
    let c = sample(uv);
    return vec4<f32>(c.rgb * shade, c.a * edge);
}
