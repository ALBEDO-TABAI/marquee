struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let amp = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);

    let a = atan2(p.y, p.x);
    let r = length(p);
    let d = r - (0.28 + 0.16 * abs(cos(a * 6.0)));
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.984, 0.573, 0.235);
    // Straight alpha, laid over what is beneath: on a see-through card
    // the antialiased edge keeps the sticker's colour rather than greying
    // towards the black of an empty pixel. Over a picture it is the same mix.
    let k = clamp(shape * amp, 0.0, 1.0);
    let out_a = k + src.a * (1.0 - k);
    let rgb = (col * k + src.rgb * src.a * (1.0 - k)) / max(out_a, 1e-4);
    return vec4<f32>(rgb, out_a);
}
