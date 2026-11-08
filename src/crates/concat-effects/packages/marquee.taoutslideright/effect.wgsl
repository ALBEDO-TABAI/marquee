struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let order = reveal_order(uv);
    let rank = order;
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let window = mix(0.20, 1.20, 1.0 - amt);
    let dur = max(frame.clip_duration, window + 0.05);
    let ct = frame.clip_time;
    let progress = clamp((dur - ct) / window, 0.0, 1.0);
    let local = smoothstep(rank - 0.045, rank + 0.22, progress);

    var suv = uv;
    suv.x = suv.x - (1.0 - local) * 0.09;
    let c = sample(suv);
    var rgb = c.rgb;
    return vec4<f32>(rgb, c.a * local);
}
