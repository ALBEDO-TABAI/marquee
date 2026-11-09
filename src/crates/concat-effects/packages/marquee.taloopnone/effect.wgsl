struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let order = reveal_order(uv);
    let rank = order;
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let ct = frame.clip_time;
    // No loop: the title as it is. (This was a copy of 闪烁 and blinked.)
    return sample(uv);
}
