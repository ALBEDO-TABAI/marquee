struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let order = reveal_order(uv);
    let rank = order;
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let ct = frame.clip_time;
    // Each glyph sways side to side a little, out of step with its
    // neighbours. Still at the start of the loop. (Was a copy of 闪烁.)
    let sway = sin(ct * mix(3.0, 9.0, amt) + rank * 6.0) - sin(rank * 6.0);
    var suv = uv;
    suv.x = suv.x + sway * mix(0.004, 0.012, amt);
    return sample(suv);
}
