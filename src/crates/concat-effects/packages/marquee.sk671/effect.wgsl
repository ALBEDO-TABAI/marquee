struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let s = 1.0 + 0.08 * sin(frame.clip_time * 5.0);
    p = p / s;
    let q = vec2<f32>(abs(p.x), p.y);
    let d0 = length(q - vec2<f32>(0.16, 0.18)) - 0.16;
    let d2 = (q.x + q.y) * 0.7 - 0.18;
    let d = min(d0, d2);
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.973, 0.980, 0.988);
    let over = mix(src.rgb, col, shape * 0.92);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
