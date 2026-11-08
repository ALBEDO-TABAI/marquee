struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let ang = frame.clip_time * 1.8;
    let cs = cos(ang); let sn = sin(ang);
    p = vec2<f32>(p.x * cs - p.y * sn, p.x * sn + p.y * cs);
    let q = abs(p);
    let d = max(q.x * 0.866 + q.y * 0.5, q.y) - 0.38;
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(0.941, 0.753, 0.314);
    let over = mix(src.rgb, col, shape * 0.92);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
