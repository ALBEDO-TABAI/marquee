struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);
    // 涂鸦: drawn by hand - the line boils, redrawn eight times a second.
    let boil = floor(frame.clip_time * 8.0);
    p = p + 0.012 * vec2<f32>(sin(boil * 12.9898), cos(boil * 78.233))
        + 0.014 * vec2<f32>(sin(p.y * 11.0 + boil * 1.7), cos(p.x * 13.0 - boil * 2.3));

    let d = (abs(p.x) + abs(p.y)) - 0.48;
    let line = 1.0 - smoothstep(0.022, 0.036, abs(d + 0.01));
    let wash = (1.0 - smoothstep(-0.02, 0.0, d)) * 0.28;
    let shape = max(line, wash);
    let col = vec3<f32>(0.004, 0.725, 0.776);
    // Straight alpha, laid over what is beneath: on a see-through card
    // the antialiased edge keeps the sticker's colour rather than greying
    // towards the black of an empty pixel. Over a picture it is the same mix.
    let k = clamp(shape * a, 0.0, 1.0);
    let out_a = k + src.a * (1.0 - k);
    let rgb = (col * k + src.rgb * src.a * (1.0 - k)) / max(out_a, 1e-4);
    return vec4<f32>(rgb, out_a);
}
