struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let ang = frame.clip_time * 1.8;
    let cs = cos(ang); let sn = sin(ang);
    p = vec2<f32>(p.x * cs - p.y * sn, p.x * sn + p.y * cs);
    // A closed heart, point down (uv runs down, so y is flipped here).
    let hs = 0.72;
    let h = vec2<f32>(abs(p.x), -p.y) / hs + vec2<f32>(0.0, 0.55);
    var hd = 0.0;
    if (h.x + h.y > 1.0) {
        hd = length(h - vec2<f32>(0.25, 0.75)) - 0.35355;
    } else {
        let e1 = h - vec2<f32>(0.0, 1.0);
        let e2 = h - 0.5 * max(h.x + h.y, 0.0);
        hd = sqrt(min(dot(e1, e1), dot(e2, e2))) * sign(h.x - h.y);
    }
    let d = hd * hs;
    let shape = 1.0 - smoothstep(-0.02, 0.03, d);
    let col = vec3<f32>(1.000, 0.361, 0.659);
    let over = mix(src.rgb, col, shape * 0.92);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
