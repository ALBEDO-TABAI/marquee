struct Params { amount: f32 }
// 综艺闪标: big cartoon stars popping in and out in the corners, variety-show style.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(1.0);
    var look = c.rgb;
    for (var i = 0; i < 4; i++) {
        let k = f32(i);
        let corner = vec2<f32>(select(0.14, 0.86, (i & 1) == 1) * aspect, select(0.18, 0.82, (i & 2) == 2));
        let local = fract(ph + k * 0.25);
        let pop = smoothstep(0.0, 0.15, local) * (1.0 - smoothstep(0.6, 0.8, local));
        let scale = 0.11 * pop * (1.0 + 0.2 * exp(-local * 12.0) * sin(local * 40.0));
        let d = p - corner;
        let ang = atan2(d.y, d.x) + t * 1.5;
        let r = length(d);
        let star = scale * (0.55 + 0.45 * pow(abs(cos(ang * 2.5)), 3.0));
        let fill = 1.0 - smoothstep(star - 0.004, star, r);
        let outline = 1.0 - smoothstep(star, star + 0.01, r);
        let col = select(vec3<f32>(1.0, 0.9, 0.15), vec3<f32>(1.0, 0.4, 0.7), (i & 1) == 1);
        look = mix(look, vec3<f32>(0.1), outline * step(0.01, scale));
        look = mix(look, col, fill * step(0.01, scale));
    }
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
