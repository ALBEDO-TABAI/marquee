struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let amp = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let s = 1.0 + 0.08 * sin(frame.clip_time * 5.0);
    p = p / s;
    let a = atan2(p.y, p.x);
    let r = length(p);
    let d = r - (0.28 + 0.16 * abs(cos(a * 6.0)));
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.204, 0.827, 0.600);
    let over = mix(src.rgb, col, shape * 0.92);
    return vec4<f32>(mix(src.rgb, over, amp), max(src.a, shape * amp));
}
