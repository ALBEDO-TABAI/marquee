struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    p.y = p.y + 0.08 * abs(sin(frame.clip_time * 6.0));
    // Point up: uv runs down, so y is flipped.
    let q = vec2<f32>(abs(p.x) * 0.95, -p.y);
    let d = max(q.x * 0.866 + q.y * 0.5, -q.y) - 0.22;
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.973, 0.980, 0.988);
    let over = mix(src.rgb, col, shape * 0.92);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
