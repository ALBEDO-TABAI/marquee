struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let order = reveal_order(uv);
    let rank = order;
    let amt = clamp(params.amount / 100.0, 0.0, 1.0);
    let window = mix(0.20, 1.20, 1.0 - amt);
    let dur = max(frame.clip_duration, window + 0.05);
    let ct = frame.clip_time;
    let progress = 0.5 + 0.5 * sin(ct * mix(2.2, 7.5, amt) + rank * 12.0);
    let local = smoothstep(rank - 0.045, rank + 0.22, progress);

    var suv = uv;
    suv.y = suv.y + sin(rank * 18.0 + ct * 9.0) * 0.018 * (1.0 - local + 0.15);
    let c = sample(suv);
    var rgb = c.rgb;
    return vec4<f32>(rgb, c.a * local);
}
