struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);
    p.y = p.y + 0.08 * abs(sin(frame.clip_time * 6.0));
    let d = abs(length(p) - 0.38) - 0.08;
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.941, 0.753, 0.314);
    let over = mix(src.rgb, col, shape);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
