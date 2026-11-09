struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let amp = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);
    let s = 1.0 + 0.08 * sin(frame.clip_time * 5.0);
    p = p / s;
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
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.886, 0.294, 0.290);
    let over = mix(src.rgb, col, shape);
    return vec4<f32>(mix(src.rgb, over, amp), max(src.a, shape * amp));
}
