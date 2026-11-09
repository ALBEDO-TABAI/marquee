struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let wobble = 1.0 + 0.03 * sin(frame.clip_time * 4.0 + f32(4));
    p = p / wobble;
    let corner = min(min(length(p - vec2<f32>(-0.7, -0.55)), length(p - vec2<f32>(0.7, -0.55))),
                     min(length(p - vec2<f32>(-0.7, 0.55)), length(p - vec2<f32>(0.7, 0.55)))) - 0.06;
    let bar = abs(p.y) - (0.62 - f32(4) * 0.04);
    let d = min(corner, abs(bar) - 0.018);
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
