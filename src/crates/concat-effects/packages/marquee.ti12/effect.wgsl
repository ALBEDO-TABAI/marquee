struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);
    let wobble = 1.0 + 0.03 * sin(frame.clip_time * 4.0 + f32(12));
    p = p / wobble;
    let boxp = abs(p) - vec2<f32>(0.72, 0.38);
    let outer = length(max(boxp, vec2<f32>(0.0))) + min(max(boxp.x, boxp.y), 0.0) - 0.100;
    let inner = length(max(boxp + vec2<f32>(0.026), vec2<f32>(0.0))) + min(max(boxp.x + 0.026, boxp.y + 0.026), 0.0) - 0.100;
    let d = max(outer, -inner);
    let shape = 1.0 - smoothstep(-0.015, 0.02, d);
    let col = vec3<f32>(0.886, 0.294, 0.290);
    // Straight alpha, laid over what is beneath: on a see-through card
    // the antialiased edge keeps the sticker's colour rather than greying
    // towards the black of an empty pixel. Over a picture it is the same mix.
    let k = clamp(shape * 0.9 * a, 0.0, 1.0);
    let out_a = k + src.a * (1.0 - k);
    let rgb = (col * k + src.rgb * src.a * (1.0 - k)) / max(out_a, 1e-4);
    return vec4<f32>(rgb, out_a);
}
