struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let amp = params.amount / 100.0;
    // Drawn in a square of the frame's shorter side, centred: a circle stays
    // round on a 16:9 picture as it is on its square card.
    var p = (uv * 2.0 - vec2<f32>(1.0)) * frame.size / min(frame.size.x, frame.size.y);
    let ang = frame.clip_time * 1.8;
    let cs = cos(ang); let sn = sin(ang);
    p = vec2<f32>(p.x * cs - p.y * sn, p.x * sn + p.y * cs);
    let a = atan2(p.y, p.x);
    let r = length(p);
    let d = r - (0.28 + 0.16 * abs(cos(a * 6.0)));
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.204, 0.827, 0.600);
    let over = mix(src.rgb, col, shape);
    return vec4<f32>(mix(src.rgb, over, amp), max(src.a, shape * amp));
}
