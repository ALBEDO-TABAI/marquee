struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let s = 1.0 + 0.08 * sin(frame.clip_time * 5.0);
    p = p / s;
    let q = vec2<f32>(abs(p.x) * 0.95, p.y);
    let d = max(q.x * 0.866 + q.y * 0.5, -q.y) - 0.22;
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.004, 0.725, 0.776);
    let over = mix(src.rgb, col, shape * 0.92);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
