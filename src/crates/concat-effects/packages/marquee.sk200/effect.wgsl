struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let amp = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);

    let a = atan2(p.y, p.x);
    let r = length(p);
    let k = 0.32 + 0.16 * abs(cos(a * 2.5));
    let d = r - k;
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.004, 0.725, 0.776);
    let over = mix(src.rgb, col, shape * 0.92);
    return vec4<f32>(mix(src.rgb, over, amp), max(src.a, shape * amp));
}
