struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let amp = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);
    // 涂鸦: drawn by hand - the line boils, redrawn eight times a second.
    let boil = floor(frame.clip_time * 8.0);
    p = p + 0.012 * vec2<f32>(sin(boil * 12.9898), cos(boil * 78.233))
        + 0.014 * vec2<f32>(sin(p.y * 11.0 + boil * 1.7), cos(p.x * 13.0 - boil * 2.3));

    // A five-point star with sharp tips, one tip up (uv runs down).
    var sq = vec2<f32>(abs(p.x), 0.05 - p.y);
    let sk1 = vec2<f32>(0.809016994, -0.587785252);
    let sk2 = vec2<f32>(-0.809016994, -0.587785252);
    sq = sq - 2.0 * max(dot(sk1, sq), 0.0) * sk1;
    sq = sq - 2.0 * max(dot(sk2, sq), 0.0) * sk2;
    sq.x = abs(sq.x);
    sq.y = sq.y - 0.52;
    let sba = 0.45 * vec2<f32>(0.587785252, 0.809016994) - vec2<f32>(0.0, 1.0);
    let sh = clamp(dot(sq, sba) / dot(sba, sba), 0.0, 0.52);
    let d = length(sq - sba * sh) * sign(sq.y * sba.x - sq.x * sba.y);
    let line = 1.0 - smoothstep(0.022, 0.036, abs(d + 0.01));
    let wash = (1.0 - smoothstep(-0.02, 0.0, d)) * 0.28;
    let shape = max(line, wash);
    let col = vec3<f32>(0.941, 0.753, 0.314);
    // Straight alpha, laid over what is beneath: on a see-through card
    // the antialiased edge keeps the sticker's colour rather than greying
    // towards the black of an empty pixel. Over a picture it is the same mix.
    let k = clamp(shape * amp, 0.0, 1.0);
    let out_a = k + src.a * (1.0 - k);
    let rgb = (col * k + src.rgb * src.a * (1.0 - k)) / max(out_a, 1e-4);
    return vec4<f32>(rgb, out_a);
}
