struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);
    let s = 1.0 + 0.08 * sin(frame.clip_time * 5.0);
    p = p / s;
    // A closed heart, point down (uv runs down, so y is flipped here).
    let hs = 0.72;
    let h = vec2<f32>(abs(p.x), -p.y) / hs + vec2<f32>(0.0, 0.55);
    var hd = 0.0;
    if (h.x + h.y > 1.0) {
        hd = length(h - vec2<f32>(0.25, 0.75)) - 0.35355;
    } else {
        let e1 = h - vec2<f32>(0.0, 1.0);
        let e2 = h - 0.5 * max(h.x + h.y, 0.0);
        hd = sqrt(min(dot(e1, e1), dot(e2, e2))) * sign(h.x - h.y);
    }
    let d = hd * hs;
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.204, 0.827, 0.600);
    // Straight alpha, laid over what is beneath: on a see-through card
    // the antialiased edge keeps the sticker's colour rather than greying
    // towards the black of an empty pixel. Over a picture it is the same mix.
    let k = clamp(shape * a, 0.0, 1.0);
    let out_a = k + src.a * (1.0 - k);
    let rgb = (col * k + src.rgb * src.a * (1.0 - k)) / max(out_a, 1e-4);
    return vec4<f32>(rgb, out_a);
}
